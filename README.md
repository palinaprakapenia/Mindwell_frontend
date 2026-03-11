# MindWell iOS App

**Project:** MindWell - Mental Health Monitoring App  
**Author:** Palina Prakapenia  

## Description
MindWell is a mobile app for mental health tracking and meditation exercises.  
Users can register, log in, track their mood, complete daily tasks, participate in global challenges, and earn experience points and rewards.  
The app connects to the MindWell backend API to store user data, while personal meditation history is saved locally using CoreData.  

## Features
- User registration and login via API  
- Track mood on the main screen  
- Daily tasks and global challenges to earn points and rewards  
- Meditation library with video files, filters, and the ability to add favorites  
- Favorites and other data are synced with the backend  
- History of meditation sessions stored locally in CoreData  
- Weekly and all-time statistics displayed in a section "Statistics" 
- Achievements for completing global challenges, mood tracking, and meditation milestones  
- User profile management and settings  

## Tools and Technologies
- Swift 5 / SwiftUI  
- Xcode 14+  
- CoreData for local storage  
- REST API integration with URLSession  
- JSON decoding for backend communication  

## Requirements
- macOS with Xcode 14+  
- iOS 15+ target  
- MindWell Backend API running (see backend repository)  

## Setup / Running the Project
1. Clone the repository:  
git clone https://github.com/palinaprakapenia/Mindwell_frontend.git  
2. Open the project in Xcode:  
MindWell.xcodeproj  
3. Configure the API endpoint in `Constants.swift` if needed:  
let apiURL = "http://localhost:5000"  
4. Build and run on a simulator or a real device  

## Notes
- The app requires the backend API to work correctly  
- Meditation history is saved locally using CoreData  
- Other user data, including favorites, is synced with the backend  
- Make sure you have a valid developer certificate for running on a real iOS device
