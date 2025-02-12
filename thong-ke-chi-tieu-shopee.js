var tongDonHang = 0;
var tongTienTietKiem = 0;
var tongtienhang = 0;
var tongtienhangchuagiam = 0;
var tongSanPhamDaMua = 0;
var trangThaiDonHangConKhong = true;
var offset = 0;
var si = 20;
document.title = 'Bắt đầu kiểm tra tiêu dùng';
function xemBaoCaoThongKe() {
    var orders = [];
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function () {
        if (this.readyState == 4 && this.status == 200) {
            orders = JSON.parse(this.responseText)['data']['details_list'];
            tongDonHang += orders.length;
            trangThaiDonHangConKhong = orders.length >= si;
            orders.forEach(order => {
                let t31 = order['info_card']['final_total'] / 100000;
                tongtienhang += t31;

                order['info_card']['order_list_cards'].forEach(item => {
                    item['product_info']['item_groups'].forEach(itemGroups => {
                        itemGroups['items'].forEach(data => {
                            let t5 = data["order_price"] / 100000;
                            tongSanPhamDaMua += data["amount"];
                            tongtienhangchuagiam += t5;
                        });
                    })
                });
            });
            offset += si;
            if (trangThaiDonHangConKhong) {
                hienThiThongBao(tongDonHang);
                xemBaoCaoThongKe();
            } else {
                tongTienTietKiem = tongtienhangchuagiam - tongtienhang;
                setTimeout(hienThiPopup, 2000);
            }
        }
    };
    xhttp.open("GET", "https://shopee.vn/api/v4/order/get_order_list?list_type=3&offset=" + offset + "&limit=" + si, true);
    xhttp.send();
}

function hienThiThongBao(tongDonHang) {
    let thongBao = document.createElement("div");
    
    // Áp dụng CSS trực tiếp vào element
    thongBao.style.position = "fixed";
    thongBao.style.top = "50%";
    thongBao.style.left = "50%";
    thongBao.style.transform = "translate(-50%, -50%)";
    thongBao.style.width = "320px";
    thongBao.style.background = "rgba(255, 255, 255, 0.95)";
    thongBao.style.padding = "20px";
    thongBao.style.borderRadius = "12px";
    thongBao.style.boxShadow = "0 10px 20px rgba(0, 0, 0, 0.2)";
    thongBao.style.textAlign = "center";
    thongBao.style.fontFamily = "Arial, sans-serif";
    thongBao.style.opacity = "0";
    thongBao.style.transition = "opacity 0.4s ease-in-out";

    thongBao.innerHTML = `
        <p style="color: #444; font-size: 16px; margin: 0 0 12px;">
            Đã quét <strong style="color: #ff5722;">${tongDonHang}</strong> đơn hàng...<br>Tiếp tục lấy dữ liệu...
        </p>`;

    document.body.appendChild(thongBao);

    // Hiệu ứng xuất hiện
    setTimeout(() => {
        thongBao.style.opacity = "1";
    }, 10);

    // Tự động ẩn sau 3 giây
    setTimeout(() => {
        thongBao.style.opacity = "0";
        setTimeout(() => { thongBao.remove(); }, 500);
    }, 2000);
}

function hienThiPopup() {
    let popup = document.createElement("div");
    popup.innerHTML = `
        <div style="position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 500px; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3); text-align: center; font-family: Arial, sans-serif;">
            <h2 style="color: #ff5722;">Báo Cáo Thống Kê Shopee</h2>
            <p><b>Số tiền đã tiêu:</b> <span style="color: #2196F3; font-size: 18px;">${pxgPrice(tongtienhang)} vnđ</span></p>
            <p><b>Tổng đơn hàng đã giao:</b> <span style="color: #4CAF50; font-size: 18px;">${pxgPrice(tongDonHang)} đơn hàng</span></p>
            <p><b>Số lượng sản phẩm đã đặt:</b> <span style="color: #E91E63; font-size: 18px;">${pxgPrice(tongSanPhamDaMua)} sản phẩm</span></p>
            <p><b>Tiền tiết kiệm được từ Voucher, Mã giảm giá:</b> <span style="color: #FF9800; font-size: 18px;">${pxgPrice(tongTienTietKiem)} vnđ</span></p>
            <button style="margin-top: 15px; padding: 10px 20px; background: #f44336; color: white; border: none; border-radius: 5px; cursor: pointer;" onclick="this.parentElement.remove()">Đóng</button>
        </div>
    `;
    document.body.appendChild(popup);
}

function pxgPrice(number, fixed = 0) {
    if (isNaN(number)) return 0;
    number = number.toFixed(fixed);
    let delimeter = ',';
    number += '';
    let rgx = /\B(?=(\d{3})+(?!\d))/g;
    return number.replace(rgx, delimeter);
}

xemBaoCaoThongKe();
