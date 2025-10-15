<div align="center">

# 🌀 My Gensyn Node Setup Guide

**The Ultimate One-Command Solution for Gensyn Node Management**

</div>

Welcome! This guide empowers you to install, manage, and troubleshoot your Gensyn node using a **single, powerful menu**. Whether you're new or experienced, everything is streamlined for your convenience.

---

## 📦 Why Choose Our Node Manager?

🚀 **All-in-One Control** - Complete node lifecycle management in one place  
⚡ **Lightning Fast Setup** - Get running in under 5 minutes with zero configuration  
🔧 **Advanced Automation** - Automated troubleshooting and system optimization  
🛡️ **Beginner Friendly** - Simple interface with guided workflows  
📊 **Pro Tools Included** - Advanced monitoring and customization options

---

## 🚀 Quick Start (One Command!)

Open your terminal and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SagarX41/GensynAuto/main/menu.sh)
```

---

## 🧠 MAIN MENU OPTIONS

```
┌─────────────────────────────────────────────────────────────────┐
│ 🟢 Option 1 🛠️ - Install/Reinstall Node - Fresh setup          │
│ 🟢 Option 2 🚀 - Start Node - Launch with auto-restart mode    │
│ 🟢 Option 3 ⚙️ - Change Settings - Customize models            │
│ 🟢 Option 4 ♻️ - Reset Peer ID - Generate fresh peer identity  │
│ 🟢 Option 5 🗑️ - Complete Reset - Full system wipe & reinstall │
│ 🟢 Option 6 📉 - Version Control - Switch between versions     │
│ 🔴 Option 7 ❌ - Exit - Safely close management interface      │
└─────────────────────────────────────────────────────────────────┘
```

🔔 **Need Help?** Check our [FAQ Section](#-faq--troubleshooting) below
=============================================================

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
