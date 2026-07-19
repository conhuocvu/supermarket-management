package com.supermarket.backend.repository;

import com.supermarket.backend.dto.SalesDTO;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class SalesRepository {
    private final NamedParameterJdbcTemplate jdbc;

    public SalesRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<SalesDTO.Shift> findCurrentShift(UUID cashierId) {
        String sql = """
                SELECT COALESCE(s.shift_name, 'Scheduled Shift') shift_name,
                       (ws.work_date + s.start_time)::timestamp shift_start,
                       CASE WHEN s.end_time <= s.start_time
                            THEN (ws.work_date + s.end_time + INTERVAL '1 day')::timestamp
                            ELSE (ws.work_date + s.end_time)::timestamp END shift_end
                FROM public.work_schedules ws
                JOIN public.shifts s ON s.shift_number = ws.shift_number
                WHERE ws.user_id = :cashierId
                  AND (ws.status IS NULL OR UPPER(CAST(ws.status AS TEXT)) = 'ASSIGNED')
                  AND (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')
                        >= (ws.work_date + s.start_time)::timestamp
                  AND (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh') < CASE
                        WHEN s.end_time <= s.start_time
                            THEN (ws.work_date + s.end_time + INTERVAL '1 day')::timestamp
                        ELSE (ws.work_date + s.end_time)::timestamp
                      END
                ORDER BY ws.work_date DESC, s.start_time DESC
                LIMIT 1
                """;
        return jdbc.query(sql, new MapSqlParameterSource("cashierId", cashierId), (rs, row) ->
                new SalesDTO.Shift(rs.getString("shift_name"),
                        rs.getObject("shift_start", LocalDateTime.class),
                        rs.getObject("shift_end", LocalDateTime.class))).stream().findFirst();
    }

    public int countInvoices(UUID cashierId, LocalDateTime start, LocalDateTime end) {
        Integer value = jdbc.queryForObject("""
                SELECT COUNT(*)
                FROM public.invoices i
                WHERE i.cashier_number = :cashierId
                  AND (i.created_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') >= :start
                  AND (i.created_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') < :end
                  AND EXISTS (
                      SELECT 1 FROM public.invoice_details d
                      WHERE d.invoice_number = i.invoice_number
                  )
                """, rangeParams(cashierId, start, end), Integer.class);
        return value == null ? 0 : value;
    }

    public int countUnpaidInvoices(UUID cashierId, LocalDateTime start, LocalDateTime end) {
        Integer value = jdbc.queryForObject("""
                SELECT COUNT(*)
                FROM public.invoices i
                WHERE i.cashier_number = :cashierId
                  AND UPPER(COALESCE(i.status, '')) = 'UNPAID'
                  AND (i.created_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') >= :start
                  AND (i.created_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') < :end
                  AND EXISTS (
                      SELECT 1 FROM public.invoice_details d
                      WHERE d.invoice_number = i.invoice_number
                  )
                """, rangeParams(cashierId, start, end), Integer.class);
        return value == null ? 0 : value;
    }

    public BigDecimal sumRevenue(UUID cashierId, LocalDateTime start, LocalDateTime end) {
        BigDecimal value = jdbc.queryForObject("""
                SELECT COALESCE(SUM(i.final_amount), 0)
                FROM public.invoices i
                WHERE i.cashier_number = :cashierId
                  AND (i.created_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') >= :start
                  AND (i.created_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') < :end
                  AND UPPER(COALESCE(i.status, '')) = 'PAID'
                  AND EXISTS (
                      SELECT 1 FROM public.invoice_details d
                      WHERE d.invoice_number = i.invoice_number
                  )
                """, rangeParams(cashierId, start, end), BigDecimal.class);
        return money(value);
    }

    public List<SalesDTO.InvoiceSummary> findInvoiceSummaries(UUID cashierId, LocalDateTime start,
            LocalDateTime end, String keyword, String status, int limit, int offset) {
        String sql = """
                SELECT i.invoice_number, COALESCE(c.full_name, 'Walk-in Customer') customer_name,
                       COALESCE(i.total_amount, 0) total_amount, COALESCE(i.final_amount, 0) final_amount,
                       i.status, pay.payment_method, i.created_date
                FROM public.invoices i
                LEFT JOIN public.customers c ON c.customer_number = i.customer_number
                LEFT JOIN LATERAL (
                    SELECT payment_method FROM public.payments p
                    WHERE p.invoice_number = i.invoice_number
                    ORDER BY p.payment_date DESC, p.payment_number DESC LIMIT 1
                ) pay ON TRUE
                WHERE i.cashier_number = :cashierId
                  AND (i.created_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') >= :start
                  AND (i.created_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') < :end
                  AND EXISTS (
                      SELECT 1 FROM public.invoice_details d
                      WHERE d.invoice_number = i.invoice_number
                  )
                  AND (:status = 'ALL' OR UPPER(COALESCE(i.status, '')) = :status)
                  AND (:keyword = '' OR CAST(i.invoice_number AS TEXT) LIKE CONCAT('%', :keyword, '%')
                       OR LOWER(COALESCE(c.full_name, '')) LIKE LOWER(CONCAT('%', :keyword, '%')))
                ORDER BY i.created_date DESC, i.invoice_number DESC LIMIT :limit OFFSET :offset
                """;
        MapSqlParameterSource params = rangeParams(cashierId, start, end)
                .addValue("keyword", keyword).addValue("status", status)
                .addValue("limit", limit).addValue("offset", offset);
        return jdbc.query(sql, params, (rs, row) -> new SalesDTO.InvoiceSummary(
                rs.getInt("invoice_number"), rs.getString("customer_name"),
                money(rs.getBigDecimal("total_amount")), money(rs.getBigDecimal("final_amount")),
                rs.getString("status"), rs.getString("payment_method"),
                rs.getObject("created_date", LocalDateTime.class)));
    }

    public long countInvoiceSummaries(UUID cashierId, LocalDateTime start, LocalDateTime end,
            String keyword, String status) {
        Long value = jdbc.queryForObject("""
                SELECT COUNT(*) FROM public.invoices i
                LEFT JOIN public.customers c ON c.customer_number = i.customer_number
                WHERE i.cashier_number = :cashierId
                  AND (i.created_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') >= :start
                  AND (i.created_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') < :end
                  AND EXISTS (
                      SELECT 1 FROM public.invoice_details d
                      WHERE d.invoice_number = i.invoice_number
                  )
                  AND (:status = 'ALL' OR UPPER(COALESCE(i.status, '')) = :status)
                  AND (:keyword = '' OR CAST(i.invoice_number AS TEXT) LIKE CONCAT('%', :keyword, '%')
                       OR LOWER(COALESCE(c.full_name, '')) LIKE LOWER(CONCAT('%', :keyword, '%')))
                """, rangeParams(cashierId, start, end).addValue("keyword", keyword).addValue("status", status),
                Long.class);
        return value == null ? 0 : value;
    }

    public List<String> findAlerts() {
        return jdbc.query("""
                SELECT CONCAT(p.product_name, ' is low in stock (',
                              COALESCE(i.available_quantity, 0), ' remaining).') alert
                FROM public.products p JOIN public.inventories i ON i.product_number = p.product_number
                WHERE i.available_quantity <= COALESCE(p.reorder_level, 0)
                ORDER BY i.available_quantity ASC LIMIT 3
                """, (rs, row) -> rs.getString("alert"));
    }

    public int createInvoice(UUID cashierId) {
        Integer id = jdbc.queryForObject("""
                INSERT INTO public.invoices(cashier_number, customer_number, total_amount,
                                            final_amount, status, created_date)
                VALUES (:cashierId, NULL, 0, 0, 'UNPAID',
                        CURRENT_TIMESTAMP AT TIME ZONE 'UTC')
                RETURNING invoice_number
                """, new MapSqlParameterSource("cashierId", cashierId), Integer.class);
        return id == null ? 0 : id;
    }

    public Optional<SalesDTO.Invoice> findInvoice(int invoiceNumber) {
        String headerSql = """
                SELECT i.invoice_number, i.cashier_number, COALESCE(p.full_name, 'Cashier') cashier_name,
                       i.customer_number, c.full_name customer_name, c.phone customer_phone,
                       c.point customer_point, COALESCE(i.total_amount, 0) total_amount,
                       COALESCE(i.final_amount, 0) final_amount, i.status, i.created_date,
                       pay.payment_method, pay.amount paid_amount
                FROM public.invoices i
                LEFT JOIN public.profiles p ON p.user_id = i.cashier_number
                LEFT JOIN public.customers c ON c.customer_number = i.customer_number
                LEFT JOIN LATERAL (
                    SELECT payment_method, amount FROM public.payments py
                    WHERE py.invoice_number = i.invoice_number
                    ORDER BY py.payment_date DESC, py.payment_number DESC LIMIT 1
                ) pay ON TRUE
                WHERE i.invoice_number = :id
                """;
        List<SalesDTO.Invoice> headers = jdbc.query(headerSql, new MapSqlParameterSource("id", invoiceNumber),
                (rs, row) -> {
                    Integer customerNumber = (Integer) rs.getObject("customer_number");
                    SalesDTO.Customer customer = customerNumber == null ? null : new SalesDTO.Customer(
                            customerNumber, rs.getString("customer_name"), rs.getString("customer_phone"),
                            rs.getInt("customer_point"));
                    return new SalesDTO.Invoice(rs.getInt("invoice_number"),
                            rs.getObject("cashier_number", UUID.class), rs.getString("cashier_name"), customer,
                            money(rs.getBigDecimal("total_amount")), money(rs.getBigDecimal("final_amount")),
                            rs.getString("status"), rs.getObject("created_date", LocalDateTime.class),
                            rs.getString("payment_method"), money(rs.getBigDecimal("paid_amount")), List.of());
                });
        if (headers.isEmpty()) return Optional.empty();
        SalesDTO.Invoice h = headers.get(0);
        return Optional.of(new SalesDTO.Invoice(h.invoiceNumber(), h.cashierId(), h.cashierName(), h.customer(),
                h.totalAmount(), h.finalAmount(), h.status(), h.createdDate(), h.paymentMethod(), h.paidAmount(),
                findInvoiceLines(invoiceNumber)));
    }

    public List<SalesDTO.InvoiceLine> findInvoiceLines(int invoiceNumber) {
        return jdbc.query("""
                SELECT d.invoice_detail_number, d.product_number, p.product_name, p.barcode,
                       d.quantity, d.unit_price_at_sale,
                       (d.quantity * d.unit_price_at_sale) line_total, p.image_url
                FROM public.invoice_details d JOIN public.products p ON p.product_number = d.product_number
                WHERE d.invoice_number = :id ORDER BY d.invoice_detail_number
                """, new MapSqlParameterSource("id", invoiceNumber), (rs, row) ->
                new SalesDTO.InvoiceLine(rs.getInt("invoice_detail_number"), rs.getInt("product_number"),
                        rs.getString("product_name"), rs.getString("barcode"),
                        money(rs.getBigDecimal("quantity")), money(rs.getBigDecimal("unit_price_at_sale")),
                        money(rs.getBigDecimal("line_total")), rs.getString("image_url")));
    }

    public List<SalesDTO.Category> findCategories() {
        return jdbc.query("""
                SELECT category_number, category_name FROM public.categories
                WHERE UPPER(status) = 'ACTIVE' ORDER BY category_name
                """, (rs, row) -> new SalesDTO.Category(rs.getInt("category_number"), rs.getString("category_name")));
    }

    public List<SalesDTO.Product> findProducts(String keyword, Integer categoryNumber) {
        String categoryFilter = categoryNumber == null
                ? ""
                : " AND p.category_number = :categoryNumber ";
        String sql = """
                SELECT p.product_number, p.category_number, c.category_name, p.product_name, p.barcode,
                       p.selling_price, COALESCE(i.available_quantity, 0) available_quantity, p.image_url,
                       CASE WHEN EXISTS (SELECT 1 FROM public.stock_in_details sid
                                         WHERE sid.product_number = p.product_number AND sid.remaining_quantity > 0)
                                  AND NOT EXISTS (SELECT 1 FROM public.stock_in_details sid
                                                  WHERE sid.product_number = p.product_number
                                                    AND sid.remaining_quantity > 0
                                                    AND (sid.expiry_date IS NULL OR sid.expiry_date >= CURRENT_DATE))
                            THEN TRUE ELSE FALSE END expired
                FROM public.products p
                LEFT JOIN public.categories c ON c.category_number = p.category_number
                LEFT JOIN public.inventories i ON i.product_number = p.product_number
                WHERE UPPER(p.status) = 'ACTIVE'
                """ + categoryFilter + """
                  AND (:keyword = '' OR LOWER(p.product_name) LIKE LOWER(CONCAT('%', :keyword, '%'))
                       OR COALESCE(p.barcode, '') LIKE CONCAT('%', :keyword, '%'))
                ORDER BY p.product_name LIMIT 100
                """;
        MapSqlParameterSource parameters = new MapSqlParameterSource("keyword", keyword);
        if (categoryNumber != null) {
            parameters.addValue("categoryNumber", categoryNumber);
        }
        return jdbc.query(sql, parameters, (rs, row) -> new SalesDTO.Product(
                rs.getInt("product_number"), (Integer) rs.getObject("category_number"),
                rs.getString("category_name"), rs.getString("product_name"), rs.getString("barcode"),
                money(rs.getBigDecimal("selling_price")), money(rs.getBigDecimal("available_quantity")),
                rs.getString("image_url"), rs.getBoolean("expired")));
    }

    public ProductSaleData productForSale(int productNumber) {
        String sql = """
                SELECT p.product_number, p.product_name, p.selling_price, p.status,
                       COALESCE(i.available_quantity, 0) available_quantity,
                       CASE WHEN EXISTS (SELECT 1 FROM public.stock_in_details sid
                                         WHERE sid.product_number = p.product_number AND sid.remaining_quantity > 0)
                                  AND NOT EXISTS (SELECT 1 FROM public.stock_in_details sid
                                                  WHERE sid.product_number = p.product_number
                                                    AND sid.remaining_quantity > 0
                                                    AND (sid.expiry_date IS NULL OR sid.expiry_date >= CURRENT_DATE))
                            THEN TRUE ELSE FALSE END expired
                FROM public.products p LEFT JOIN public.inventories i ON i.product_number = p.product_number
                WHERE p.product_number = :id
                """;
        return jdbc.query(sql, new MapSqlParameterSource("id", productNumber), (rs, row) ->
                new ProductSaleData(rs.getInt("product_number"), rs.getString("product_name"),
                        money(rs.getBigDecimal("selling_price")), rs.getString("status"),
                        money(rs.getBigDecimal("available_quantity")), rs.getBoolean("expired")))
                .stream().findFirst().orElse(null);
    }

    public String lockInvoiceStatus(int invoiceNumber) {
        return jdbc.query("SELECT status FROM public.invoices WHERE invoice_number = :id FOR UPDATE",
                new MapSqlParameterSource("id", invoiceNumber), (rs, row) -> rs.getString("status"))
                .stream().findFirst().orElse(null);
    }

    public BigDecimal currentItemQuantity(int invoiceNumber, int productNumber) {
        return jdbc.query("""
                SELECT quantity FROM public.invoice_details
                WHERE invoice_number = :invoice AND product_number = :product
                """, new MapSqlParameterSource("invoice", invoiceNumber).addValue("product", productNumber),
                (rs, row) -> money(rs.getBigDecimal("quantity"))).stream().findFirst().orElse(BigDecimal.ZERO);
    }

    public void upsertItem(int invoiceNumber, int productNumber, BigDecimal quantity, BigDecimal unitPrice) {
        int updated = jdbc.update("""
                UPDATE public.invoice_details SET quantity = :quantity, unit_price_at_sale = :unitPrice
                WHERE invoice_number = :invoice AND product_number = :product
                """, itemParams(invoiceNumber, productNumber, quantity).addValue("unitPrice", unitPrice));
        if (updated == 0) {
            jdbc.update("""
                    INSERT INTO public.invoice_details(invoice_number, product_number, quantity, unit_price_at_sale)
                    VALUES (:invoice, :product, :quantity, :unitPrice)
                    """, itemParams(invoiceNumber, productNumber, quantity).addValue("unitPrice", unitPrice));
        }
    }

    public InvoiceDetailIdentity findDetail(int detailId) {
        return jdbc.query("""
                SELECT invoice_number, product_number, quantity FROM public.invoice_details
                WHERE invoice_detail_number = :id
                """, new MapSqlParameterSource("id", detailId), (rs, row) ->
                new InvoiceDetailIdentity(rs.getInt("invoice_number"), rs.getInt("product_number"),
                        money(rs.getBigDecimal("quantity")))).stream().findFirst().orElse(null);
    }

    public int countInvoiceItems(int invoiceNumber) {
        Integer value = jdbc.queryForObject("""
                SELECT COUNT(*) FROM public.invoice_details
                WHERE invoice_number = :invoice
                """, new MapSqlParameterSource("invoice", invoiceNumber), Integer.class);
        return value == null ? 0 : value;
    }

    public void updateDetailQuantity(int detailId, BigDecimal quantity) {
        jdbc.update("UPDATE public.invoice_details SET quantity = :quantity WHERE invoice_detail_number = :id",
                new MapSqlParameterSource("id", detailId).addValue("quantity", quantity));
    }

    public void deleteDetail(int detailId) {
        jdbc.update("DELETE FROM public.invoice_details WHERE invoice_detail_number = :id",
                new MapSqlParameterSource("id", detailId));
    }

    public void recalculateInvoice(int invoiceNumber) {
        jdbc.update("""
                UPDATE public.invoices i SET total_amount = totals.total, final_amount = totals.total
                FROM (SELECT COALESCE(SUM(quantity * unit_price_at_sale), 0) total
                      FROM public.invoice_details WHERE invoice_number = :id) totals
                WHERE i.invoice_number = :id
                """, new MapSqlParameterSource("id", invoiceNumber));
    }

    public void cancelInvoice(int invoiceNumber) {
        jdbc.update("UPDATE public.invoices SET status = 'CANCELLED' WHERE invoice_number = :id",
                new MapSqlParameterSource("id", invoiceNumber));
    }

    public Optional<SalesDTO.Customer> findCustomerByPhone(String phone) {
        return jdbc.query("""
                SELECT customer_number, full_name, phone, point FROM public.customers WHERE phone = :phone
                """, new MapSqlParameterSource("phone", phone), (rs, row) -> new SalesDTO.Customer(
                rs.getInt("customer_number"), rs.getString("full_name"), rs.getString("phone"), rs.getInt("point")))
                .stream().findFirst();
    }

    public Optional<SalesDTO.Customer> findCustomerById(int id) {
        return jdbc.query("""
                SELECT customer_number, full_name, phone, point FROM public.customers WHERE customer_number = :id
                """, new MapSqlParameterSource("id", id), (rs, row) -> new SalesDTO.Customer(
                rs.getInt("customer_number"), rs.getString("full_name"), rs.getString("phone"), rs.getInt("point")))
                .stream().findFirst();
    }

    public Optional<SalesDTO.Customer> lockCustomerById(int id) {
        return jdbc.query("""
                SELECT customer_number, full_name, phone, point
                FROM public.customers
                WHERE customer_number = :id
                FOR UPDATE
                """, new MapSqlParameterSource("id", id), (rs, row) -> new SalesDTO.Customer(
                rs.getInt("customer_number"), rs.getString("full_name"), rs.getString("phone"), rs.getInt("point")))
                .stream().findFirst();
    }

    public SalesDTO.Customer createCustomer(String fullName, String phone) {
        return jdbc.query("""
                INSERT INTO public.customers(full_name, phone, point) VALUES (:name, :phone, 0)
                RETURNING customer_number, full_name, phone, point
                """, new MapSqlParameterSource("name", fullName).addValue("phone", phone), (rs, row) ->
                new SalesDTO.Customer(rs.getInt("customer_number"), rs.getString("full_name"),
                        rs.getString("phone"), rs.getInt("point"))).get(0);
    }

    public void linkCustomer(int invoiceNumber, Integer customerNumber) {
        jdbc.update("UPDATE public.invoices SET customer_number = :customer WHERE invoice_number = :invoice",
                new MapSqlParameterSource("invoice", invoiceNumber).addValue("customer", customerNumber));
    }

    public List<SalesDTO.Promotion> findEligiblePromotions(int invoiceNumber) {
        String sql = """
                SELECT p.promotion_number, p.promotion_name, p.discount_value,
                       COALESCE(SUM(CASE WHEN EXISTS (
                           SELECT 1 FROM public.promotion_products pp
                           WHERE pp.promotion_number = p.promotion_number
                             AND pp.product_number = d.product_number
                             AND UPPER(COALESCE(pp.status, 'ACTIVE')) = 'ACTIVE'
                       ) THEN d.quantity * d.unit_price_at_sale ELSE 0 END), 0) eligible_amount
                FROM public.promotions p CROSS JOIN public.invoice_details d
                WHERE d.invoice_number = :invoice AND UPPER(CAST(p.status AS TEXT)) = 'ACTIVE'
                  AND p.start_date <= CURRENT_DATE AND p.end_date >= CURRENT_DATE
                GROUP BY p.promotion_number, p.promotion_name, p.discount_value
                HAVING COALESCE(SUM(CASE WHEN EXISTS (
                    SELECT 1 FROM public.promotion_products pp
                    WHERE pp.promotion_number = p.promotion_number
                      AND pp.product_number = d.product_number
                      AND UPPER(COALESCE(pp.status, 'ACTIVE')) = 'ACTIVE'
                ) THEN d.quantity * d.unit_price_at_sale ELSE 0 END), 0) > 0
                ORDER BY p.discount_value DESC
                """;
        return jdbc.query(sql, new MapSqlParameterSource("invoice", invoiceNumber), (rs, row) -> {
            BigDecimal eligible = money(rs.getBigDecimal("eligible_amount"));
            BigDecimal percent = money(rs.getBigDecimal("discount_value"));
            BigDecimal discount = money(eligible.multiply(percent).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP));
            return new SalesDTO.Promotion(rs.getInt("promotion_number"), rs.getString("promotion_name"),
                    percent, eligible, discount);
        });
    }

    public void updateInvoiceForPayment(int invoiceNumber, Integer customerNumber,
            BigDecimal totalAmount, BigDecimal finalAmount) {
        jdbc.update("""
                UPDATE public.invoices SET customer_number = :customer, total_amount = :total,
                    final_amount = :final, status = 'PAID'
                WHERE invoice_number = :invoice
                """, new MapSqlParameterSource("invoice", invoiceNumber).addValue("customer", customerNumber)
                .addValue("total", totalAmount).addValue("final", finalAmount));
    }

    public LocalDateTime insertPayment(int invoiceNumber, String method, BigDecimal amount) {
        return jdbc.query("""
                INSERT INTO public.payments(invoice_number, payment_method, amount, status, payment_date)
                VALUES (:invoice, :method, :amount,
                    (SELECT e.enumlabel::payment_status
                     FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
                     WHERE t.typname = 'payment_status'
                     ORDER BY CASE UPPER(e.enumlabel)
                         WHEN 'COMPLETED' THEN 1 WHEN 'PAID' THEN 2 WHEN 'SUCCESS' THEN 3 ELSE 99 END
                     LIMIT 1), CURRENT_TIMESTAMP AT TIME ZONE 'UTC')
                RETURNING payment_date
                """, new MapSqlParameterSource("invoice", invoiceNumber).addValue("method", method)
                .addValue("amount", amount), (rs, row) -> rs.getObject("payment_date", LocalDateTime.class)).get(0);
    }

    public void updateCustomerPoints(int customerNumber, int pointsUsed, int pointsEarned) {
        jdbc.update("""
                UPDATE public.customers SET point = GREATEST(0, COALESCE(point, 0) - :used + :earned)
                WHERE customer_number = :customer
                """, new MapSqlParameterSource("customer", customerNumber).addValue("used", pointsUsed)
                .addValue("earned", pointsEarned));
    }

    public BigDecimal lockInventory(int productNumber) {
        return jdbc.query("""
                SELECT available_quantity FROM public.inventories
                WHERE product_number = :product FOR UPDATE
                """, new MapSqlParameterSource("product", productNumber),
                (rs, row) -> money(rs.getBigDecimal("available_quantity"))).stream().findFirst().orElse(BigDecimal.ZERO);
    }

    public void deductInventory(int productNumber, BigDecimal quantity) {
        int updated = jdbc.update("""
                UPDATE public.inventories
                SET available_quantity = available_quantity - :quantity,
                    total_quantity = total_quantity - :quantity, last_updated = NOW()
                WHERE product_number = :product AND available_quantity >= :quantity
                """, new MapSqlParameterSource("product", productNumber).addValue("quantity", quantity));
        if (updated != 1) throw new IllegalStateException("Insufficient inventory.");
    }

    public List<StockBatch> lockSellableBatches(int productNumber) {
        return jdbc.query("""
                SELECT stock_in_detail_number, remaining_quantity
                FROM public.stock_in_details
                WHERE product_number = :product AND remaining_quantity > 0
                  AND (expiry_date IS NULL OR expiry_date >= CURRENT_DATE)
                ORDER BY expiry_date ASC NULLS LAST, stock_in_detail_number ASC FOR UPDATE
                """, new MapSqlParameterSource("product", productNumber), (rs, row) ->
                new StockBatch(rs.getInt("stock_in_detail_number"), money(rs.getBigDecimal("remaining_quantity"))));
    }

    public void deductBatch(int batchId, BigDecimal quantity) {
        jdbc.update("""
                UPDATE public.stock_in_details SET remaining_quantity = remaining_quantity - :quantity
                WHERE stock_in_detail_number = :batch
                """, new MapSqlParameterSource("batch", batchId).addValue("quantity", quantity));
    }

    public void insertSaleTransaction(int productNumber, Integer batchId, BigDecimal quantity,
            int invoiceNumber, UUID cashierId) {
        jdbc.update("""
                INSERT INTO public.inventory_transactions(product_number, stock_in_detail_number,
                    type, quantity, reference_type, reference_id, created_by, created_at)
                VALUES (:product, :batch, CAST('OUT' AS transaction_type), :quantity,
                    'INVOICE', :invoice, :cashier, NOW())
                """, new MapSqlParameterSource("product", productNumber).addValue("batch", batchId)
                .addValue("quantity", quantity).addValue("invoice", invoiceNumber)
                .addValue("cashier", cashierId));
    }

    public LocalDateTime findLatestPaymentDate(int invoiceNumber) {
        return jdbc.query("""
                SELECT payment_date FROM public.payments WHERE invoice_number = :invoice
                ORDER BY payment_date DESC, payment_number DESC LIMIT 1
                """, new MapSqlParameterSource("invoice", invoiceNumber),
                (rs, row) -> rs.getObject("payment_date", LocalDateTime.class))
                .stream().findFirst().orElse(null);
    }

    private MapSqlParameterSource rangeParams(UUID cashierId, LocalDateTime start, LocalDateTime end) {
        return new MapSqlParameterSource("cashierId", cashierId).addValue("start", start).addValue("end", end);
    }

    private MapSqlParameterSource itemParams(int invoice, int product, BigDecimal quantity) {
        return new MapSqlParameterSource("invoice", invoice).addValue("product", product)
                .addValue("quantity", quantity);
    }

    private BigDecimal money(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value.setScale(2, RoundingMode.HALF_UP);
    }

    public record ProductSaleData(int productNumber, String productName, BigDecimal price,
            String status, BigDecimal availableQuantity, boolean expired) {}
    public record InvoiceDetailIdentity(int invoiceNumber, int productNumber, BigDecimal quantity) {}
    public record StockBatch(int stockInDetailNumber, BigDecimal remainingQuantity) {}
}
