# 📷 Pictro – Swipe-to-Review Photo App

https://github.com/user-attachments/assets/2a86f0b7-2f00-42f1-a710-d3d7b2ec1280

# Project Overview

Pictro is an iOS app that helps users clean up their photo library with a dating-app-style interaction:
- 📅 Month-based grouping for contextual photo review
- 👆 Swipe right to keep, 👈 swipe left to delete
- 🗑️ Deletion queue to prevent mistakes and allow batch actions
- ✅ Completion feedback showing stats after finishing a month to encourage consistent cleanup

With this interaction design, users can easily keep their albums neat and clutter-free.

---

# Key Features
- **Month List**: Photos are grouped by month, clearly showing review progress.  
- **Swipe Review**: Tinder-like card interface for swiping left to delete, right to keep.  
- **Progress Tracking**: Real-time statistics on kept, deleted, and completed photos.  

---

# AI-Assisted Development

In this project, I explored different AI-assisted workflows to accelerate development and refactoring:
- 🤖 Rapid generation of swipe animations, photo permissions, and services via LLM.  
- 📑 Large-scale scan: LLM generated a full Engineering Design Document (EDD) to identify dead code and duplicates.  
- 🎯 Targeted scan: Precise code inspection for specific classes/structs with optimized token usage and improved access control.  
- 🧩 Code refactoring through private extensions (Subview, Private Methods).  
- 🧹 Consistent cleanup: Removed unnecessary logs and applied a unified header comment:  
  `// Created with Claude Code AI-driven development by William.`

---

# 專案介紹

Pictro 是一款 iOS App，讓使用者以「交友軟體式」的互動方式整理相簿：
- 📅 依月份分組：幫助使用者有脈絡地回顧過去的照片
- 👆 右滑保留、👈 左滑刪除：快速決定照片去留
- 🗑️ 刪除佇列：避免誤刪，並支援批次處理
- ✅ 完成回饋：整理完某個月份後，顯示完成狀態與統計數據，鼓勵養成定期清理習慣

透過這樣的互動設計，使用者能輕鬆刪除不需要的照片，保持相簿整潔。

---

# 功能特色
- **月份列表 (Month List)**：照片依月份分類，清楚顯示整理進度。  
- **滑動審查 (Swipe Review)**：仿 Tinder 的卡片介面，左滑刪除、右滑保留。  
- **進度追蹤 (Progress Tracking)**：即時統計保留、刪除與完成比例。  

---

# AI 加速開發的應用

在這個專案中，我嘗試了多種 AI 輔助開發方式，加速理解架構與重構程式碼：
- 🤖 快速生成：LLM 幫助產出卡片滑動動畫、相簿權限處理與 Service。  
- 📑 大型掃描：由 LLM 產生完整 Engineering Design Document (EDD)，快速找出死碼與重複檔案，清理無用程式。  
- 🎯 針對性掃描：對指定 class/struct 執行精準分析，降低 token 使用，並自動補齊 access control。  
- 🧩 程式碼重構：請 LLM 透過 private extension (Subview, Private Methods) 重組程式碼。  
- 🧹 統一清理：刪除多餘的 log，並加上標準化檔頭：  
  `// Created with Claude Code AI-driven development by William.`

