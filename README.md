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

Open your terminal and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SagarX41/GensynAuto/main/menu.sh)
```

---

## 🧠 MAIN MENU OPTIONS

Below are the key features and capabilities our menu provides:

### **Menu Options & What They Do**

| Option Number | Icon | Feature | Description |
|---------------|--------|---------|-------------|
| **1** | 🛠️ | **Install/Reinstall Node** | Complete node installation with all dependencies, auto-configurations, and troubleshooting tools |
| **2** | 🚀 | **Start Node** | Launches your node with multiple run modes (auto-restart, single run, or fresh install) |
| **3** | ⚙️ | **Change Settings** | Customize model selection, Hugging Face integration, and AI market participation |
| **4** | ♻️ | **Reset Peer ID** | Generate new peer identity and clear all node data for fresh start |
| **5** | 🗑️ | **Complete Clean Reset** | Full system wipe and optional fresh reinstallation |
| **6** | 📉 | **Version Control** | Switch between different versions for compatibility |
| **7** | ❌ | **Exit** | Safely close the management interface |
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
