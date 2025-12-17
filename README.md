## Bộ script `record_pc_src` – Ghi màn hình & đồng bộ dữ liệu

Folder này chứa **bộ script ghi màn hình, gom log và đẩy dữ liệu lên server**, kèm script cài đặt Task Scheduler tự động chạy khi bật máy/đăng nhập Windows.

---

## 1. Cấu trúc thư mục

- **`install_task.bat`**  
  Script cài đặt môi trường và tạo 2 Scheduled Task:
  - Task chụp màn hình định kỳ.
  - Task gom dữ liệu & upload lên server.

- **`runtime\`**
  - **`screens.bat`**: Chụp toàn bộ màn hình định kỳ và lưu thành file JPG.
  - **`run_hidden.vbs`**: Chạy `screens.bat` ở chế độ ẩn cửa sổ (không hiện CMD).

- **`getdata\`**
  - **`post.bat`**: Gom dữ liệu từ máy người dùng, copy lên server theo IP.
  - **`run_shutdown.vbs`**: Chạy `post.bat` ở chế độ ẩn, sau đó (nếu thành công) gọi `remove.vbs`.
  - **`remove.vbs`**: Xóa các folder dữ liệu đã post `C:\ProgramData\WinRC`
- **`updata\`**
  - **`uprecordpc.bat`**: Script riêng để **đẩy dữ liệu từ thư mục tập trung `D:\Record_PC` lên NAS** theo mapping IP → tên máy.
  - **`mapusername.txt`**: Bảng map `IP|Tên hiển thị trên server`.

---

## 2. Cách làm việc của hệ thống

1. **Cài đặt & chuẩn bị**
   - Bạn copy cả folder `record_pc_src` (hoặc bản build `rcpc`) lên USB / ổ mạng.
   - Trên máy cần cài, chạy **`install_task.bat`** với quyền **Run as administrator**.

2. **`install_task.bat` làm gì?**
   - Xóa thư mục cũ `C:\ProgramData\WinRC` (nếu có).
   - Tạo lại:
     - `C:\ProgramData\WinRC\`
     - `C:\ProgramData\WinRC\src\`
   - Tìm trên các ổ D, E, F, … Z xem có thư mục `rcpc` không, nếu có sẽ copy:
     - Từ `rcpc\runtime\` → `run_hidden.vbs`, `screens.bat`.
     - Từ `rcpc\getdata\` → `remove.vbs`, `run_shutdown.vbs`, `post.bat`.
   - Kiểm tra đủ file cần thiết, nếu thiếu sẽ báo lỗi và thoát.
   - Tạo 2 Scheduled Task:
     - **`screens`**  
       - Kiểu `ONLOGON` (chạy khi user đăng nhập).  
       - Chạy: `wscript.exe "C:\ProgramData\WinRC\src\run_hidden.vbs"`  
       - User: `%USERNAME%`, quyền **Highest**.
     - **`post_data`**  
       - Kiểu `ONLOGON`.  
       - Chạy: `wscript.exe "C:\ProgramData\WinRC\src\run_shutdown.vbs"`  
       - User: `SYSTEM`, quyền **Highest**.
   - Sau khi tạo xong, script sẽ thử `Run` 2 task này để test.

3. **Task chụp màn hình (`screens`)**
   - `run_hidden.vbs` gọi ẩn:  
     - `cmd /c C:\ProgramData\WinRC\src\screens.bat`
   - `screens.bat`:
     - Tạo thư mục gốc: `BASE = C:\ProgramData\WinRC`.
     - Vòng lặp vô hạn:
       - Lấy ngày hiện tại theo dạng `dd-MM-yyyy`, ví dụ `17-12-2025`.
       - Tạo thư mục ngày: `C:\ProgramData\WinRC\dd-MM-yyyy`.
       - Tạo tên file ảnh: `dd-MM-yyyy_HH-mm-ss.jpg`.
       - Chụp màn hình với thời gian cố định

4. **Task upload & dọn dẹp (`post_data`)**
   - `run_shutdown.vbs`:
     - Chạy `post.bat` ẩn.
     - Nếu thấy file `C:\ProgramData\WinRC\src\post.success.txt` thì tiếp tục chạy `remove.vbs` để dọn file cũ.

   - `post.bat`:
     - Lấy IP của máy
     - Ghép đường dẫn UNC:  
       - `\\10.0.0.10\Record_PC\<MYIP>`
     - Vòng lặp **retry vô hạn**: nếu server chưa ping được hoặc share chưa connect được, script sẽ:
       - Báo lỗi, `timeout 30s`, rồi thử lại.
     - Khi connect được:
       - Tạo folder `\\10.0.0.10\Record_PC\<MYIP>` nếu chưa có.
       - Với mỗi thư mục ngày trong `C:\ProgramData\WinRC\??-??-????`:
         - Dùng `robocopy` copy toàn bộ nội dung lên UNC tương ứng.
         - Nếu OK, xóa thư mục ngày local.
       - Sau khi xong, xóa kết nối share, tạo file `post.success.txt` báo thành công.

   - `remove.vbs`:
     - Mở thư mục `C:\ProgramData\WinRC`.
     - Xác định các thư mục con có tên dạng `dd-MM-yyyy`.
     - Xóa tất cả folder giúp không bị đầy ổ đĩa.

---

## 3. Script `updata\uprecordpc.bat`

Đây là script **chạy trên máy NAS hoặc máy quản trị**, dùng để **gom dữ liệu đã tập trung về `D:\Record_PC` và đẩy tiếp lên share NAS chính**.

- Biến chính:
  - `SRC = D:\Record_PC` – Thư mục chứa dữ liệu đã gom theo IP.
  - `SERVER = \\192.168.0.254\data\IT\RECORD_PC` – Thư mục đích trên NAS.
  - `MAP = ...\mapusername.txt` – File map IP → tên máy hiển thị.
  - `USER`, `PASS` – Tài khoản dùng để `net use` vào NAS.
- Cách chạy:
  - Dùng `net use` để mount `\\192.168.0.254\data`.
  - Đọc từng dòng trong `mapusername.txt` với format:  
    - `IP|Tên hiển thị` (ví dụ: `192.168.0.94|Hữu Tài`).
  - Với mỗi dòng:
    - Kiểm tra thư mục local: `D:\Record_PC\<IP>`.
    - Nếu có:
      - Tính `DEST = \\192.168.0.254\data\IT\RECORD_PC\<Tên hiển thị>`.
      - Tạo thư mục đích nếu chưa có.
      - Duyệt tất cả thư mục ngày `??-??-????` bên trong IP và copy.
      - Nếu thành công, xóa toàn bộ thư mục `D:\Record_PC\<IP>`.
  - Sau khi xong, `net use /delete` để ngắt kết nối.

---

## 4. Quy trình sử dụng đề xuất

- **Trên từng máy người dùng**
  1. Copy bộ cài (có chứa `runtime\`, `getdata\`, `install_task.bat`) vào máy.
  2. Chạy `install_task.bat` với quyền admin.
  3. Kiểm tra trong Task Scheduler:
     - Có 2 task `screens` và `post_data`.
  4. Đảm bảo máy có thể ping tới `10.0.0.10` và truy cập được share `Record_PC`.

- **Trên server gom dữ liệu / NAS trung gian (nếu dùng `D:\Record_PC`)**
  1. Đảm bảo `D:\Record_PC` chứa dữ liệu theo IP.
  2. Cập nhật file `mapusername.txt` cho đúng IP ↔ tên máy.
  3. Chạy `uprecordpc.bat` định kỳ (hoặc tạo Task Scheduler riêng) để đẩy lên NAS `\\192.168.0.254\data\IT\RECORD_PC`.