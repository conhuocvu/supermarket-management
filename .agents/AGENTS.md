# Quy tắc Phát triển Dự án AgentHub (AGENTS.md)

Tệp này chứa các quy tắc thiết kế và lập trình bắt buộc mà mọi AI Agent và thành viên lập trình cần tuân thủ khi viết code cho dự án AgentHub.

---

## 🎨 1. UI Checklist (Quy chuẩn giao diện)

Mọi giao diện phải được xây dựng dựa trên Design System đã định hình trong `src/renderer/index.css`:

* **Màu sắc (Colors):**
  - Luôn sử dụng các biến CSS HSL để đảm bảo giao diện tối và tương phản tốt: `var(--md-sys-color-primary)`, `var(--md-sys-color-background)`, `var(--md-sys-color-surface-container)`.
  - Không tự định nghĩa mã màu tĩnh (`#ffffff`, `#000000`, `red`, `blue`) trong inline style hoặc class Tailwind tự chế, trừ các nhãn trạng thái đặc biệt.
* **Khoảng cách & Căn lề (Padding & Margin):**
  - Lề ngoài các khối màn hình lớn: sử dụng `p-lg` (24px).
  - Khoảng cách giữa các phần tử trong danh sách hoặc form: sử dụng `gap-md` (16px) hoặc `gap-sm` (12px).
  - Đệm dòng trong bảng (Table padding): sử dụng `px-md py-sm` để đảm bảo bảng thông thoáng, dễ đọc.
* **Căn giữa Form & Modal (Form Alignments):**
  - Luôn căn giữa tuyệt đối các màn hình đăng nhập/đăng ký (`items-center justify-center min-h-screen`).
  - Các ô nhập liệu (inputs) và nút (buttons) luôn chiếm hết chiều rộng cột cha (`w-full`) để không bị co méo.
* **Bo tròn & Hiệu ứng hover (Border Radius & Micro-interactions):**
  - Các thẻ thông tin, card chứa chỉ số: sử dụng bo góc `rounded-xl` (12px) hoặc `rounded-2xl` (16px).
  - Thêm hiệu ứng hover phóng to nhẹ (`hover:scale-[1.01] active:scale-[0.99] transition-all`) và tăng sáng viền nhẹ để tạo trải nghiệm sinh động.

---

## 📱 2. Quy tắc Responsive (Tương thích hiển thị)

Dự án phát triển trên nền ElectronJS nhưng người dùng có thể thay đổi kích thước cửa sổ rất linh hoạt:

* **App Shell:** 
  - Sidebar chính chỉ hiển thị từ màn hình trung bình trở lên (`md:flex hidden`).
  - Khi màn hình nhỏ hơn `md`, phải ẩn Sidebar và hiển thị nút **Hamburger Menu** mở Mobile Drawer hoặc Bottom Nav.
* **Bảng dữ liệu (Data Tables):**
  - Luôn bọc thẻ `table` trong một `div` có lớp `overflow-x-auto` để chống tràn layout ngang trên thiết bị di động.
* **Grid Layouts:**
  - Hàng thống kê KPI luôn sử dụng grid phản hồi: `grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-md` để tự dồn hàng trên mobile.
* **Drawer Panels:**
  - Drawer chi tiết luôn dùng chiều rộng động: `w-full sm:w-[400px]` (full màn hình trên mobile và 400px trên desktop).

---

## 🛡️ 3. Quy tắc xử lý lỗi toàn cục (Global Error Handling)

* **Bắt lỗi tại Service Layer:**
  - Tất cả các thao tác tương tác API hoặc Supabase phải được bọc trong block `try-catch`.
  - Không ném lỗi thô ra ngoài UI. Hãy chuyển đổi mã lỗi từ Supabase thành thông báo tiếng Việt thân thiện với người dùng trước khi hiển thị.
* **Thông báo trên giao diện:**
  - Sử dụng modal/alert có màu sắc tương ứng (`bg-error/10 border-error/20 text-error`) để thông báo lỗi đăng nhập hoặc lỗi kết nối.
  - Các lỗi chạy nền của Agent phải được ghi nhận vào cơ sở dữ liệu `agent_logs` (Level: `'ERROR'`) để vẽ đồ thị cảnh báo và chuyển đổi trạng thái Agent sang `'ERROR'`.
