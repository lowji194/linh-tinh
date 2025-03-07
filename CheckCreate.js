async function checkCreate(uid) {
    const api = 'https://www.facebook.com/api/graphql/';

    const data = new URLSearchParams({
        'av': '0', // Thay thế bằng giá trị thực tế nếu có
        'dpr': '1',
        '__comet_req': '15',
        'fb_dtsg': fb_dtsg,
        'fb_api_caller_class': 'RelayModern',
        'fb_api_req_friendly_name': 'MarketplaceSellerProfileDialogQuery',
        'variables': JSON.stringify({
            "isCOBMOB": false,
            "isSelfProfile": false,
            "productID": "944605867143682",
            "scale": 1,
            "sellerId": uid,
            "useContextualViewHeader": true
        }),
        'server_timestamps': 'true',
        'doc_id': '7089290281172095'
    });

    try {
        const response = await fetch(api, {
            method: 'POST',
            body: data
        });

        const responseText = await response.text(); // Đọc phản hồi dưới dạng văn bản
        console.log(responseText); // In ra phản hồi thô

        const responseJson = JSON.parse(responseText); // Cố gắng phân tích JSON
        const user = responseJson.data.user;
        const items = user.items;
        const nodes = items.nodes;

        nodes.forEach(node => {
            const text = node.title.text;
            console.log(text);
        });
    } catch (error) {
        console.error(error);
    }
}

// Gọi hàm với uid mặc định là '4'
checkCreate(4);
