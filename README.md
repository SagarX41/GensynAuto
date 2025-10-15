<div align="center">

# 🌀 My Gensyn Node Setup Guide

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
First Create Screen ( for vps users only )
```bash
screen -S gensyn
```

Open your terminal and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SagarX41/GensynAuto/main/menu.sh)
```

---

## 🧠 GENSYN MAIN MENU PREVIEW

You'll see a menu like this:

```text
==================== 🧠 GENSYN MAIN MENU ====================
1. 🛠  Install/Reinstall Node
2. 🚀  Run Node
3. ⚙️  Update Node
4. ♻️  Reset Peer ID
5. 🗑️  Delete Everything & Start New
6. 📉  Downgrade Version
7. ❌ Exit
=============================================================
```

### **What Each Option Does**

| Option | Action |
|--------|--------|
| 🛠 **Install/Reinstall Node** | Installs or updates your node to the latest version. |
| 🚀 **Run Node** | Starts your node (after setup/config). |
| ⚙️ **Update Node** | Update Node |
| ♻️ **Reset Peer ID** | Generates a new Peer ID for your node. |
| 🗑️ **Delete Everything & Start New** | Wipes all data for a fresh start. |
| 📉 **Downgrade Version** | Downgrade Node Version. |
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

## ❓ FAQ & Troubleshooting

For detailed FAQs and troubleshooting, check:  
👉 [Gensyn FAQ & Troubleshooting Guide](./gensyn-faq-troubleshooting.md)

---
