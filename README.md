<div align="center">

# 🌀 Gensyn Node Unified Setup Guide

**The Ultimate One-Command Solution for Gensyn Node Management**

</div>

Welcome! This guide empowers you to install, manage, and troubleshoot your Gensyn node using a **single, powerful menu**. Whether you're new or experienced, everything is streamlined for your convenience.

---

## 📦 Why Use This Menu?

- **All-in-One Control:** Install, run, update, fix, or reset your node—no manual steps.
- **Zero Hassle:** No downloads, no guesswork, no confusion.
- **Advanced Features:** Power tools for pros, simplicity for beginners.

---

## 🚀 Quick Start (One Command!)

Open your terminal and run ( For vps users:- create screen to run in background ):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/HustleAirdrops/Gensyn-Advanced-Solutions/main/menu.sh)
```

---

## 🧠 GENSYN MAIN MENU PREVIEW

You'll see a menu like this:

```text
==================== 🧠 GENSYN MAIN MENU ====================
1. 🛠  Install/Reinstall Node
2. 🚀 Run Node
3. ⚙️  Update Configuration
4. 🔧 Fix All Errors
5. ♻️  Reset Peer ID
6. 🗑️  Delete Everything & Start New
7. ❌ Exit
=============================================================
```

### **What Each Option Does**

| Option | Action |
|--------|--------|
| 🛠 **Install/Reinstall Node** | Installs or updates your node to the latest version. |
| 🚀 **Run Node** | Starts your node (after setup/config). |
| ⚙️ **Update Configuration** | Change node settings (model, params, etc). |
| 🔧 **Fix All Errors** | Auto-fix dependencies and common issues. |
| ♻️ **Reset Peer ID** | Generates a new Peer ID for your node. |
| 🗑️ **Delete Everything & Start New** | Wipes all data for a fresh start. |
| ❌ **Exit** | Closes the menu. |

---

## 🌐 Login Instructions

### **If Running Locally**

- A browser window should open automatically.
- If not, visit [http://localhost:3000/](http://localhost:3000/) manually.
- Login with your email, enter the OTP, and return to your terminal.

### **If Running on VPS/Server**

- In a new terminal/tab, run:
    ```bash
    cloudflared tunnel --url http://localhost:3000
    ```
- Open the provided link in your browser, login, and return to the node terminal.

---

## 🔐 Backup Your Credentials

To safely backup your credentials, run:

```bash
[ -f backup.sh ] && rm backup.sh; curl -sSL -O https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/backup.sh && chmod +x backup.sh && ./backup.sh
```

---

## 🏆 Check Your Rewards

- Go to [@GensynReward_bot](https://t.me/GensynReward_bot) on Telegram.
- Send `/add` and your Peer ID to track rewards.

**Important:**  
If you see `0x0000000000000000000000000000000000000000` as your EOA address, your work is **not** being recorded.
- Delete the `swarm.pem` file.
- Restart setup with a new email.

---

## 💬 Need Help?

- **Direct Support:** [@Legend_Aashish](https://t.me/Legend_Aashish)
- **Guides & Updates:** [@Hustle_Airdrops](https://t.me/Hustle_Airdrops)

---

## ❓ FAQ & Troubleshooting

For detailed FAQs and troubleshooting, check:  
👉 [Gensyn FAQ & Troubleshooting Guide](./gensyn-faq-troubleshooting.md)

---
