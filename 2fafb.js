
(function () {
  'use strict';

  const CONFIG = {
    BRAND: 'easyme.pro',
    VERSION: '1.0',
    API_URL: 'https://accountscenter.facebook.com/api/graphql/'
  };

  let popupElement = null;
  let isProcessing = false;

  const accountInfo = {
    uid: '',
    fb_dtsg: '',
    lsd: ''
  };

  // Lấy ID người dùng hiện tại
  function getCurrentUserId() {
    try {
      return require('CurrentUserInitialData').USER_ID;
    } catch (e) {
      try {
        const match = document.cookie.match(/c_user=(\d+)/);
        return match ? match[1] : null;
      } catch {
        return null;
      }
    }
  }

  // Lấy token fb_dtsg
  function getFbDtsgToken() {
    try {
      return require('DTSGInitialData').token;
    } catch (e) {
      try {
        const html = document.documentElement.innerHTML;
        const regexes = [
          /"DTSGInitialData"[^}]*"token":"([^"]+)"/,
          /name="fb_dtsg" value="([^"]+)"/,
          /"fb_dtsg":"([^"]+)"/
        ];
        for (const regex of regexes) {
          const match = html.match(regex);
          if (match) return match[1];
        }
        return null;
      } catch {
        return null;
      }
    }
  }

  // Lấy token lsd
  function getLsdToken() {
    try {
      const html = document.documentElement.innerHTML;
      const regexes = [
        /"LSD"[^}]*"token":"([^"]+)"/,
        /name="lsd" value="([^"]+)"/,
        /"lsd":"([^"]+)"/
      ];
      for (const regex of regexes) {
        const match = html.match(regex);
        if (match) return match[1];
      }
      return null;
    } catch {
      return null;
    }
  }

  // Tạo UUID ngẫu nhiên cho client_mutation_id
  function generateClientMutationId() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  // Chuyển secret key dạng base32 sang Uint8Array
  function base32Decode(base32String) {
    base32String = base32String.replace(/\s+/g, '').toUpperCase();
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    let bits = '';
    for (let char of base32String) {
      const index = alphabet.indexOf(char);
      if (index === -1) continue;
      bits += index.toString(2).padStart(5, '0');
    }
    const bytes = [];
    for (let i = 0; i + 8 <= bits.length; i += 8) {
      bytes.push(parseInt(bits.substr(i, 8), 2));
    }
    return new Uint8Array(bytes);
  }

  // Tạo chữ ký HMAC-SHA1
  async function hmacSign(keyBytes, data) {
    const key = await crypto.subtle.importKey(
      'raw',
      keyBytes,
      { name: 'HMAC', hash: 'SHA-1' },
      false,
      ['sign']
    );
    const signature = await crypto.subtle.sign('HMAC', key, data);
    return new Uint8Array(signature);
  }

  // Sinh mã TOTP 6 số
  async function generateTotpCode(secretBase32, customTime = null, timeStep = 30, digits = 6) {
    const key = base32Decode(secretBase32);
    const now = customTime || Date.now();
    const counter = Math.floor(now / 1000 / timeStep);

    const buffer = new ArrayBuffer(8);
    const view = new DataView(buffer);
    view.setUint32(4, counter >>> 0, false); // big-endian

    const hmac = await hmacSign(key, new Uint8Array(buffer));
    const offset = hmac[hmac.length - 1] & 0xf;

    const binary =
      ((hmac[offset] & 0x7f) << 24) |
      ((hmac[offset + 1] & 0xff) << 16) |
      ((hmac[offset + 2] & 0xff) << 8) |
      (hmac[offset + 3] & 0xff);

    return (binary % Math.pow(10, digits)).toString().padStart(digits, '0');
  }

  // Gọi API tạo secret key mới
  async function requestGenerateTotpKey() {
    const payload = {
      input: {
        client_mutation_id: generateClientMutationId(),
        actor_id: accountInfo.uid,
        account_id: accountInfo.uid,
        account_type: 'FACEBOOK',
        device_id: 'device_id_fetch_datr',
        fdid: 'device_id_fetch_datr'
      }
    };

    const params = new URLSearchParams({
      av: accountInfo.uid,
      __user: accountInfo.uid,
      __a: '1',
      fb_dtsg: accountInfo.fb_dtsg,
      lsd: accountInfo.lsd,
      fb_api_caller_class: 'RelayModern',
      fb_api_req_friendly_name: 'useFXSettingsTwoFactorGenerateTOTPKeyMutation',
      variables: JSON.stringify(payload),
      doc_id: '9837172312995248'
    });

    const res = await fetch(CONFIG.API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: params,
      credentials: 'include'
    });

    const serverTime = res.headers.get('Date')
      ? new Date(res.headers.get('Date')).getTime()
      : null;

    return {
      json: await res.json(),
      serverTime
    };
  }

  // Gọi API bật 2FA bằng mã TOTP
  async function requestEnableTotp(code) {
    const payload = {
      input: {
        client_mutation_id: generateClientMutationId(),
        actor_id: accountInfo.uid,
        account_id: accountInfo.uid,
        account_type: 'FACEBOOK',
        verification_code: code,
        device_id: 'device_id_fetch_datr',
        fdid: 'device_id_fetch_datr'
      }
    };

    const params = new URLSearchParams({
      av: accountInfo.uid,
      __user: accountInfo.uid,
      __a: '1',
      fb_dtsg: accountInfo.fb_dtsg,
      lsd: accountInfo.lsd,
      fb_api_caller_class: 'RelayModern',
      fb_api_req_friendly_name: 'useFXSettingsTwoFactorEnableTOTPMutation',
      variables: JSON.stringify(payload),
      doc_id: '29164158613231327'
    });

    const res = await fetch(CONFIG.API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: params,
      credentials: 'include'
    });

    return await res.json();
  }

  // ====================== PHẦN GIAO DIỆN ======================

  function createEl(tag, props = {}, children = []) {
    const el = document.createElement(tag);
    for (const [k, v] of Object.entries(props)) {
      if (k === 'style' && typeof v === 'object') {
        Object.assign(el.style, v);
      } else if (k === 'style') {
        el.style.cssText = v;
      } else if (k.startsWith('on')) {
        el[k] = v;
      } else if (k !== 'textContent') {
        el.setAttribute(k, v);
      } else {
        el.textContent = v;
      }
    }
    children.forEach(child => {
      if (typeof child === 'string') {
        el.appendChild(document.createTextNode(child));
      } else if (child) {
        el.appendChild(child);
      }
    });
    return el;
  }

  function showMainPopup() {
    // Xóa popup cũ nếu có
    document.getElementById('tfa-popup')?.remove();
    popupElement?.remove();

    // Thêm style animation
    if (!document.getElementById('tfa-styles')) {
      const style = document.createElement('style');
      style.id = 'tfa-styles';
      style.textContent = `
        @keyframes tfaFadeIn  { from { opacity: 0; } to { opacity: 1; } }
        @keyframes tfaSlideIn { from { transform: translateY(-30px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
        @keyframes tfaSpin    { to { transform: rotate(360deg); } }
      `;
      document.head.appendChild(style);
    }

    const overlay = createEl('div', {
      id: 'tfa-popup',
      style: 'position:fixed;inset:0;background:rgba(0,0,0,0.7);backdrop-filter:blur(5px);z-index:99999;display:flex;align-items:center;justify-content:center;animation:tfaFadeIn 0.3s ease;'
    });

    const modal = createEl('div', {
      style: 'background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);border-radius:16px;max-width:550px;width:95%;box-shadow:0 25px 60px rgba(0,0,0,0.4);animation:tfaSlideIn 0.4s ease;overflow:hidden;'
    });

    // Header
    const header = createEl('div', {
      style: 'background:rgba(255,255,255,0.1);padding:20px 28px;border-bottom:1px solid rgba(255,255,255,0.1);display:flex;align-items:center;justify-content:space-between;'
    }, [
      createEl('div', {}, [
        createEl('h2', {
          style: 'color:#fff;font-size:22px;font-weight:700;margin:0;text-shadow:0 2px 4px rgba(0,0,0,0.2);',
          textContent: '🔐 TURN ON 2FA'
        }),
        createEl('p', {
          style: 'color:rgba(255,255,255,0.8);font-size:12px;margin:5px 0 0 0;',
          textContent: `${CONFIG.BRAND} v${CONFIG.VERSION}`
        })
      ]),
      createEl('button', {
        id: 'tfaClose',
        style: 'background:rgba(255,255,255,0.15);border:none;color:#fff;width:36px;height:36px;border-radius:50%;font-size:20px;cursor:pointer;display:flex;align-items:center;justify-content:center;',
        textContent: '×',
        onclick: closePopup
      })
    ]);

    const content = createEl('div', { style: 'background:#fff;padding:28px;' });

    // Info box
    content.appendChild(createEl('div', {
      style: 'background:#e3f2fd;border:1px solid #90caf9;border-radius:10px;padding:14px;margin-bottom:20px;'
    }, [
      createEl('div', { style: 'font-size:13px;color:#1565c0;' }, [
        createEl('strong', { textContent: 'ℹ️ Info: ' }),
        'Công cụ này sẽ tự động bật xác thực hai yếu tố (2FA) bằng ứng dụng Authenticator cho tài khoản Facebook của bạn.'
      ])
    ]));

    // Account ID
    content.appendChild(createEl('div', {
      style: 'background:#f8f9fa;border-radius:10px;padding:16px;margin-bottom:20px;'
    }, [
      createEl('div', { style: 'font-size:13px;color:#666;margin-bottom:8px;', textContent: 'Account ID:' }),
      createEl('div', {
        id: 'tfaUid',
        style: 'font-size:18px;font-weight:700;color:#333;',
        textContent: accountInfo.uid || 'Đang tải...'
      })
    ]));

    // Kết quả thành công
    const successBox = createEl('div', { id: 'tfaResult', style: 'display:none;' }, [
      createEl('div', {
        style: 'background:#e8f5e9;border:2px solid #4caf50;border-radius:10px;padding:20px;margin-bottom:16px;'
      }, [
        createEl('div', { style: 'text-align:center;margin-bottom:12px;' }, [
          createEl('span', { style: 'font-size:48px;', textContent: '✅' })
        ]),
        createEl('div', {
          style: 'text-align:center;font-size:16px;font-weight:700;color:#2e7d32;margin-bottom:16px;',
          textContent: '2FA Đã Bật Thành Công!'
        }),
        createEl('div', {
          style: 'background:#fff;border-radius:8px;padding:16px;margin-bottom:12px;'
        }, [
          createEl('div', {
            style: 'font-size:12px;color:#666;margin-bottom:8px;text-align:center;',
            textContent: '🔑 Secret Key của bạn (LƯU LẠI NGAY):'
          }),
          createEl('div', {
            id: 'tfaSecretKey',
            style: 'font-size:18px;font-weight:700;color:#333;text-align:center;font-family:monospace;letter-spacing:2px;word-break:break-all;'
          })
        ])
      ]),
      createEl('div', { style: 'display:flex;gap:12px;' }, [
        createEl('button', {
          id: 'tfaCopyKey',
          style: 'flex:1;padding:14px;border:none;border-radius:10px;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff;font-size:14px;font-weight:600;cursor:pointer;',
          textContent: '📋 Copy Key'
        }),
        createEl('button', {
          id: 'tfaSaveFile',
          style: 'flex:1;padding:14px;border:none;border-radius:10px;background:linear-gradient(135deg,#4caf50 0%,#388e3c 100%);color:#fff;font-size:14px;font-weight:600;cursor:pointer;',
          textContent: '💾 Lưu File'
        })
      ])
    ]);

    // Lỗi
    const errorBox = createEl('div', { id: 'tfaError', style: 'display:none;' }, [
      createEl('div', {
        style: 'background:#ffebee;border:2px solid #f44336;border-radius:10px;padding:20px;margin-bottom:16px;'
      }, [
        createEl('div', { style: 'text-align:center;margin-bottom:12px;' }, [
          createEl('span', { style: 'font-size:48px;', textContent: '❌' })
        ]),
        createEl('div', {
          style: 'text-align:center;font-size:16px;font-weight:700;color:#c62828;margin-bottom:8px;',
          textContent: 'Bật 2FA Thất Bại'
        }),
        createEl('div', { id: 'tfaErrorMsg', style: 'text-align:center;font-size:13px;color:#666;' })
      ])
    ]);

    // Yêu cầu mật khẩu / reauth
    const passwordChallenge = createEl('div', { id: 'tfaPasswordChallenge', style: 'display:none;' }, [
      createEl('div', {
        style: 'background:#fff3e0;border:2px solid #ff9800;border-radius:10px;padding:20px;margin-bottom:16px;'
      }, [
        createEl('div', { style: 'text-align:center;margin-bottom:12px;' }, [
          createEl('span', { style: 'font-size:48px;', textContent: '🔒' })
        ]),
        createEl('div', {
          style: 'text-align:center;font-size:16px;font-weight:700;color:#e65100;margin-bottom:12px;',
          textContent: 'Yêu cầu xác minh mật khẩu'
        }),
        createEl('div', {
          style: 'text-align:center;font-size:13px;color:#666;margin-bottom:16px;',
          textContent: 'Facebook yêu cầu xác minh mật khẩu trước khi bật 2FA. Nhấn nút bên dưới để mở trang cài đặt 2FA, nhập mật khẩu, sau đó chạy lại tool này.'
        }),
        createEl('button', {
          id: 'tfaGoToSettings',
          style: 'width:100%;padding:14px;border:none;border-radius:10px;background:linear-gradient(135deg,#ff9800 0%,#f57c00 100%);color:#fff;font-size:14px;font-weight:600;cursor:pointer;box-shadow:0 4px 15px rgba(255,152,0,0.4);',
          textContent: '🔗 Mở trang 2FA Settings',
          onclick: () => { window.location.href = 'https://accountscenter.facebook.com/password_and_security/two_factor'; }
        })
      ])
    ]);

    // Nút chính
    const mainButtons = createEl('div', { id: 'tfaMainBtns' }, [
      createEl('div', { style: 'display:flex;gap:12px;' }, [
        createEl('button', {
          id: 'tfaCancel',
          style: 'flex:1;padding:14px;border:2px solid #e1e5e9;border-radius:10px;background:#f8f9fa;color:#666;font-size:15px;font-weight:600;cursor:pointer;',
          textContent: 'Hủy',
          onclick: closePopup
        }),
        createEl('button', {
          id: 'tfaStart',
          style: 'flex:2;padding:14px;border:none;border-radius:10px;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff;font-size:15px;font-weight:600;cursor:pointer;box-shadow:0 4px 15px rgba(102,126,234,0.4);',
          textContent: '🚀 BẬT 2FA NGAY',
          onclick: startProcess
        })
      ])
    ]);

    // Đang xử lý
    const processing = createEl('div', {
      id: 'tfaProcessing',
      style: 'display:none;text-align:center;padding:20px;'
    }, [
      createEl('div', {
        style: 'width:50px;height:50px;border:4px solid #e1e5e9;border-top-color:#667eea;border-radius:50%;animation:tfaSpin 1s linear infinite;margin:0 auto 16px;'
      }),
      createEl('div', {
        id: 'tfaStatus',
        style: 'font-size:14px;color:#666;',
        textContent: 'Đang tạo secret key...'
      })
    ]);

    content.appendChild(successBox);
    content.appendChild(errorBox);
    content.appendChild(passwordChallenge);
    content.appendChild(mainButtons);
    content.appendChild(processing);

    // Footer
    const footer = createEl('div', {
      style: 'background:#f8f9fa;padding:12px 24px;text-align:center;font-size:12px;color:#666;border-top:1px solid #e1e5e9;'
    }, [
      'Join ',
      createEl('a', {
        href: 'https://t.me/' + CONFIG.BRAND.replace(/\./g, ''),
        target: '_blank',
        rel: 'noopener noreferrer',
        style: 'color:#667eea;text-decoration:none;font-weight:600;',
        textContent: 'Telegram'
      }),
      ' for updates | ',
      createEl('a', {
        href: 'https://www.' + CONFIG.BRAND,
        target: '_blank',
        rel: 'noopener noreferrer',
        style: 'color:#764ba2;text-decoration:none;font-weight:600;',
        textContent: CONFIG.BRAND
      })
    ]);

    modal.appendChild(header);
    modal.appendChild(content);
    modal.appendChild(footer);

    overlay.appendChild(modal);
    document.body.appendChild(overlay);
    popupElement = overlay;

    // Cập nhật UID
    document.getElementById('tfaUid').textContent = accountInfo.uid || 'Không lấy được UID';
  }

  function closePopup() {
    if (isProcessing && !confirm('Đang xử lý. Bạn có chắc muốn đóng?')) return;
    popupElement?.remove();
    popupElement = null;
  }

  function updateStatus(text) {
    const el = document.getElementById('tfaStatus');
    if (el) el.textContent = text;
  }

  function setProcessing(active) {
    isProcessing = active;
    document.getElementById('tfaMainBtns').style.display = active ? 'none' : 'block';
    document.getElementById('tfaProcessing').style.display = active ? 'block' : 'none';
  }

  function showSuccess(secretKey) {
    document.getElementById('tfaResult').style.display = 'block';
    document.getElementById('tfaSecretKey').textContent = secretKey;

    document.getElementById('tfaCopyKey').onclick = function () {
      navigator.clipboard.writeText(secretKey);
      this.textContent = '✓ Đã copy!';
      setTimeout(() => this.textContent = '📋 Copy Key', 3000);
    };

    document.getElementById('tfaSaveFile').onclick = function () {
      const content = [
        'Facebook 2FA Secret Key',
        '========================',
        `Account ID: ${accountInfo.uid}`,
        `Secret Key: ${secretKey}`,
        `Generated: ${new Date().toLocaleString()}`,
        '========================',
        'Giữ bí mật key này! Dùng để nhập vào app Authenticator.'
      ].join('\n');

      const blob = new Blob([content], { type: 'text/plain' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `2FA_${accountInfo.uid}.txt`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);

      this.textContent = '✓ Đã lưu!';
      setTimeout(() => this.textContent = '💾 Lưu File', 3000);
    };
  }

  function showError(message) {
    document.getElementById('tfaError').style.display = 'block';
    document.getElementById('tfaErrorMsg').textContent = message;
  }

  function showPasswordRequired(isReauth = false) {
    const box = document.getElementById('tfaPasswordChallenge');
    if (!box) return;

    box.style.display = 'block';
    const icon = box.querySelector('span');
    const title = box.querySelector('div:nth-child(2)');
    const desc = box.querySelector('div:nth-child(3)');

    if (isReauth) {
      if (icon) icon.textContent = '🔐';
      if (title) title.textContent = 'Xác minh danh tính';
      if (desc) desc.textContent = 'Facebook yêu cầu xác minh danh tính. Vui lòng vào trang cài đặt 2FA, hoàn tất xác minh, sau đó chạy lại tool.';
    } else {
      if (icon) icon.textContent = '🔒';
      if (title) title.textContent = 'Yêu cầu mật khẩu';
      if (desc) desc.textContent = 'Facebook yêu cầu xác minh mật khẩu trước khi bật 2FA. Nhấn nút bên dưới để mở trang cài đặt, nhập mật khẩu, sau đó chạy lại tool.';
    }
  }

  // Quy trình chính
  async function startProcess() {
    setProcessing(true);
    updateStatus('Đang tạo secret key...');

    try {
      const { json: genResponse, serverTime } = await requestGenerateTotpKey();

      if (genResponse?.data?.errors?.length > 0) {
        const err = genResponse.data.errors[0];
        let msg = err.summary || err.message || 'Lỗi không xác định';

        try {
          const desc = JSON.parse(err.description || '{}');
          if (desc.challenge_type === 'password' || desc.challenge_type === 'reauth') {
            setProcessing(false);
            showPasswordRequired(desc.challenge_type === 'reauth');
            return;
          }
        } catch {}

        throw new Error(msg);
      }

      const secret = genResponse.data.data.xfb_two_factor_generate_totp_key.totp_key.key_text;
      const cleanSecret = secret.replace(/\s+/g, '');

      updateStatus('Đang sinh mã xác thực...');
      let totpCode = await generateTotpCode(cleanSecret, serverTime);

      updateStatus('Đang bật 2FA...');
      let enableResponse = await requestEnableTotp(totpCode);

      // Thử lại 1 lần nếu thất bại (dùng thời gian mới nhất)
      if (!enableResponse?.data?.xfb_two_factor_enable_totp?.success) {
        updateStatus('Thử lại với thời gian mới...');
        const freshHead = await fetch(CONFIG.API_URL, { method: 'HEAD', credentials: 'include' });
        const freshTime = new Date(freshHead.headers.get('Date')).getTime();
        totpCode = await generateTotpCode(cleanSecret, freshTime);
        enableResponse = await requestEnableTotp(totpCode);
      }

      if (enableResponse?.data?.xfb_two_factor_enable_totp?.success) {
        setProcessing(false);
        showSuccess(cleanSecret);
      } else {
        throw new Error(enableResponse?.data?.xfb_two_factor_enable_totp?.error_message || 'Không bật được 2FA');
      }

    } catch (err) {
      console.error('[easyme.pro] Lỗi:', err);
      setProcessing(false);
      showError(err.message || 'Đã xảy ra lỗi không xác định');
    }
  }

  // Khởi động
  function init() {
    console.log(`[${CONFIG.BRAND}] Turn On 2FA v${CONFIG.VERSION}`);

    accountInfo.uid = getCurrentUserId();
    accountInfo.fb_dtsg = getFbDtsgToken();
    accountInfo.lsd = getLsdToken();

    showMainPopup();

    if (!window.location.href.startsWith('https://accountscenter.facebook.com')) {
      document.getElementById('tfaMainBtns').style.display = 'none';
      const challenge = document.getElementById('tfaPasswordChallenge');
      if (challenge) {
        challenge.style.display = 'block';
        const icon = challenge.querySelector('span');
        const title = challenge.querySelector('div:nth-child(2)');
        const desc = challenge.querySelector('div:nth-child(3)');

        if (icon) icon.textContent = '⚠️';
        if (title) title.textContent = 'Sai trang';
        if (desc) desc.textContent = 'Tool này chỉ chạy được trên trang Account Center. Nhấn nút bên dưới để mở trang 2FA Settings, sau đó chạy lại.';
      }
      return;
    }

    if (!accountInfo.uid || !accountInfo.fb_dtsg) {
      showError('Không lấy được thông tin tài khoản. Hãy refresh trang và thử lại.');
    }
  }

  init();
})();
