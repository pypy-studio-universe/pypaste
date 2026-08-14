# PyPaste — Hướng dẫn sử dụng / User Guide

## Tiếng Việt

### 1. Giới thiệu

PyPaste là ứng dụng quản lý clipboard dành cho macOS. Ứng dụng lưu lịch sử sao chép trên
máy, giúp tìm kiếm, xem trước, sắp xếp và dán lại nội dung nhanh bằng bàn phím hoặc chuột.

Yêu cầu hệ thống: macOS 14 Sonoma trở lên.

### 2. Cài đặt

1. Mở trang **Releases** của dự án trên GitHub.
2. Tải file `PyPaste-v0.1.0-macOS-universal.zip`.
3. Giải nén và kéo `PyPaste.app` vào thư mục **Applications**.
4. Mở PyPaste từ Applications.
5. Nếu macOS chặn bản thử nghiệm chưa notarize, nhấp phải vào `PyPaste.app`, chọn **Open**,
   rồi xác nhận **Open**. Chỉ cài file tải từ trang Releases chính thức của dự án.

> Bản 0.1.0 hiện là bản thử nghiệm dành cho phát triển. Bản phát hành công khai chính thức
> nên được ký bằng Developer ID và notarize trước khi phân phối rộng rãi.

### 3. Quyền cần cấp

#### Accessibility — cần cho chức năng tự động dán

PyPaste cần quyền Accessibility để gửi tổ hợp `⌘V` đến ứng dụng bạn đang dùng sau khi chọn
một item. Không có quyền này, PyPaste vẫn sao chép item vào clipboard nhưng bạn phải tự nhấn
`⌘V`.

Cách cấp quyền:

1. Mở **System Settings**.
2. Chọn **Privacy & Security** → **Accessibility**.
3. Bật công tắc cho **PyPaste**. Nếu chưa có PyPaste trong danh sách, nhấn `+` và chọn
   `/Applications/PyPaste.app`.
4. Thoát hoàn toàn PyPaste và mở lại ứng dụng.

Nếu PyPaste vẫn liên tục hỏi quyền sau khi đã bật:

1. Thoát PyPaste.
2. Xóa mục PyPaste cũ khỏi danh sách Accessibility bằng nút `−`.
3. Mở đúng bản `/Applications/PyPaste.app`, thêm lại và bật quyền.
4. Thoát rồi mở lại PyPaste một lần nữa.

#### Files and Folders — có thể được hỏi khi nhập ảnh chụp màn hình

PyPaste theo dõi thư mục lưu ảnh chụp màn hình của macOS để tự đưa ảnh mới vào lịch sử và
hiển thị preview. macOS có thể yêu cầu quyền truy cập Desktop hoặc thư mục ảnh chụp tùy chỉnh.
Hãy chọn **Allow** nếu muốn dùng tính năng này.

PyPaste không yêu cầu Full Disk Access. Nếu từ chối quyền thư mục, clipboard thông thường vẫn
hoạt động; chỉ tính năng tự nhập ảnh chụp được lưu thành file có thể không hoạt động.

#### Clipboard và mạng

- macOS không có hộp thoại cấp quyền riêng cho việc đọc clipboard của ứng dụng macOS này.
- Mạng chỉ được dùng để tải metadata/ảnh preview của liên kết HTTP(S). Khi offline hoặc tải
  thất bại, PyPaste dùng preview đơn giản từ URL. Nội dung clipboard không được đồng bộ lên
  máy chủ của PyPaste.

### 4. Mở Quick Bar và dán nội dung

1. Sao chép nội dung trong ứng dụng bất kỳ.
2. Nhấn `⌘⇧V` để mở hoặc đóng Quick Bar ở cạnh dưới màn hình.
3. Dùng `←` và `→` để chọn item.
4. Nhấn `Return` để sao chép và tự động dán item đã chọn; hoặc nhấp trực tiếp vào card.
5. Nhấn `Esc` để đóng hộp thoại đang mở trước, sau đó nhấn `Esc` lần nữa để đóng Quick Bar.

Quick Bar tự đóng khi PyPaste mất focus theo cấu hình hiện tại.

### 5. Tính năng chính

- **Lịch sử clipboard:** lưu text, rich text, link, màu HEX, ảnh, PDF, file và nhiều item theo
  đúng thứ tự representation ban đầu.
- **Tìm kiếm gần đúng:** tìm theo tiêu đề, nội dung, tên ứng dụng nguồn, bundle identifier và
  loại dữ liệu.
- **Preview:** hiển thị thumbnail ảnh/ảnh chụp màn hình, màu HEX đúng màu và preview link có
  tiêu đề, domain, ảnh khi tải được.
- **Nguồn sao chép:** mỗi card hiển thị tên ứng dụng nơi nội dung được sao chép.
- **Collections:** Clipboard là danh mục mặc định. Có thể tạo danh mục, thêm item và giữ item
  đó lâu dài qua lần thoát ứng dụng hoặc khởi động lại máy, cho đến khi chủ động xóa.
- **Kéo thả để sắp xếp:** kéo card sang vị trí mới; rail/glow hiển thị vị trí trước hoặc sau
  trước khi thả. Thứ tự được lưu sau khi mở lại ứng dụng.
- **Kéo sang ứng dụng khác:** kéo nội dung trực tiếp từ PyPaste sang ứng dụng macOS hỗ trợ.
- **Xóa:** đưa chuột lên card hoặc collection và dùng nút `×`; xóa collection cần xác nhận và
  không xóa nội dung clipboard gốc của item.
- **Ảnh chụp màn hình:** ảnh mới do công cụ Screenshot của macOS lưu thành file có thể tự động
  được đưa vào clipboard PyPaste và xem trước.
- **Pause/Resume:** tạm dừng hoặc tiếp tục theo dõi clipboard từ menu bar.
- **Ngôn ngữ:** chọn Tiếng Việt hoặc English trong menu **Language** ở menu bar.

### 6. Menu bar

Nhấp biểu tượng `py` trên menu bar để:

- Mở cửa sổ chính bằng **Open PyPaste**.
- Mở Quick Bar bằng **Show Quick Bar**.
- Tạm dừng/tiếp tục theo dõi clipboard.
- Chọn ngôn ngữ trong **Language**.
- Thoát ứng dụng bằng **Quit PyPaste**.

### 7. Khắc phục sự cố

- **`⌘⇧V` không hoạt động:** thoát các bản PyPaste khác, mở lại một bản duy nhất và kiểm tra
  shortcut có bị ứng dụng khác chiếm không.
- **Chọn item nhưng không tự dán:** kiểm tra Accessibility; nếu chưa cấp, nội dung vẫn đã được
  copy và có thể dán thủ công bằng `⌘V`.
- **Ảnh chụp màn hình không xuất hiện:** kiểm tra quyền thư mục và vị trí lưu screenshot trong
  tùy chọn Screenshot của macOS.
- **Preview link không có ảnh:** kiểm tra mạng; một số trang chặn tải metadata nên PyPaste sẽ
  dùng preview URL dự phòng.
- **Hai biểu tượng hoặc hai menu:** thoát toàn bộ tiến trình PyPaste rồi chỉ mở bản trong
  Applications.

### 8. Quyền riêng tư

Lịch sử và collections được lưu cục bộ trên máy. Hãy xóa nội dung nhạy cảm khi không còn cần,
tạm dừng monitoring khi làm việc với mật khẩu, và chỉ cấp các quyền cần thiết cho tính năng bạn
muốn dùng.

---

## English

### 1. Overview

PyPaste is a native clipboard manager for macOS. It stores clipboard history locally and lets
you search, preview, organize, and paste content quickly with the keyboard or mouse.

System requirement: macOS 14 Sonoma or later.

### 2. Installation

1. Open the project's GitHub **Releases** page.
2. Download `PyPaste-v0.1.0-macOS-universal.zip`.
3. Unzip it and drag `PyPaste.app` into **Applications**.
4. Open PyPaste from Applications.
5. If macOS blocks the non-notarized development preview, right-click `PyPaste.app`, choose
   **Open**, and confirm **Open**. Install only artifacts from the official project Releases page.

> Version 0.1.0 is currently a development preview. A public production release should be
> signed with Developer ID and notarized before broad distribution.

### 3. Required permissions

#### Accessibility — required for automatic paste

PyPaste needs Accessibility permission to send `⌘V` to the application you were using after
you select an item. Without this permission, PyPaste still copies the item to the clipboard, but
you must press `⌘V` manually.

To grant access:

1. Open **System Settings**.
2. Select **Privacy & Security** → **Accessibility**.
3. Enable **PyPaste**. If it is missing, click `+` and select
   `/Applications/PyPaste.app`.
4. Quit PyPaste completely and launch it again.

If PyPaste keeps requesting access after it is enabled:

1. Quit PyPaste.
2. Remove the old PyPaste row from Accessibility with the `−` button.
3. Launch the exact `/Applications/PyPaste.app`, add it again, and enable it.
4. Quit and relaunch PyPaste once more.

#### Files and Folders — may be requested for screenshot import

PyPaste watches the macOS screenshot destination so that new screenshots can be added to
history and previewed. macOS may request access to Desktop or a custom screenshot directory.
Choose **Allow** if you want this feature.

PyPaste does not require Full Disk Access. If directory access is denied, regular clipboard
capture still works; only automatic import of screenshots saved as files may be unavailable.

#### Clipboard and network

- macOS does not show a separate clipboard permission dialog for this macOS application.
- Network access is used only to load metadata and preview images for HTTP(S) links. When
  offline or when loading fails, PyPaste falls back to a simple URL preview. Clipboard content
  is not synchronized to a PyPaste server.

### 4. Open the Quick Bar and paste

1. Copy content in any application.
2. Press `⌘⇧V` to show or hide the Quick Bar at the bottom of the screen.
3. Use `←` and `→` to select an item.
4. Press `Return` to copy and automatically paste the selected item, or click its card.
5. Press `Esc` to close an active dialog first, then press `Esc` again to close the Quick Bar.

The Quick Bar currently closes when PyPaste loses focus.

### 5. Main features

- **Clipboard history:** captures text, rich text, links, HEX colors, images, PDFs, files, and
  multiple items while preserving original representation order.
- **Fuzzy search:** searches title, content, source application, bundle identifier, and type.
- **Preview:** renders image and screenshot thumbnails, real HEX colors, and rich link cards with
  a title, domain, and image when available.
- **Copy source:** every card shows the application where the content was copied.
- **Collections:** Clipboard is the default view. Create collections and add items that remain
  protected across app restarts and computer reboots until explicitly removed.
- **Drag to reorder:** drag a card to a new position; a rail and glow preview whether it will land
  before or after the target. The order persists after relaunch.
- **Drag to another app:** drag original clipboard content from PyPaste to a compatible macOS app.
- **Delete:** hover a card or collection and use `×`; collection deletion requires confirmation
  and does not delete the underlying clip.
- **Screenshots:** newly saved macOS screenshots can be imported automatically and previewed.
- **Pause/Resume:** pause or resume clipboard observation from the menu bar.
- **Language:** choose Vietnamese or English from the menu bar **Language** submenu.

### 6. Menu bar

Click the `py` menu bar icon to:

- Open the main window with **Open PyPaste**.
- Open the Quick Bar with **Show Quick Bar**.
- Pause or resume clipboard monitoring.
- Choose a language under **Language**.
- Exit with **Quit PyPaste**.

### 7. Troubleshooting

- **`⌘⇧V` does not work:** quit duplicate PyPaste builds, launch only one copy, and check whether
  another app owns the shortcut.
- **An item is copied but not pasted automatically:** check Accessibility. You can still paste
  manually with `⌘V`.
- **Screenshots do not appear:** verify directory permission and the screenshot destination in
  the macOS Screenshot options.
- **A link has no image:** check the network. Some websites block metadata requests, so PyPaste
  displays the fallback URL preview.
- **Two icons or menus appear:** quit every PyPaste process and launch only the copy in Applications.

### 8. Privacy

History and collections are stored locally. Remove sensitive content when it is no longer needed,
pause monitoring while handling passwords, and grant only the permissions required by the
features you use.
