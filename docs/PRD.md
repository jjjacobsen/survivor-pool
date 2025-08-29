# Survivor Pool Application - Product Requirements Document

## Overview

An elimination pool application for the TV show Survivor, where players pick contestants they believe won't be eliminated each week. The last player standing wins the pool.

## Core Game Rules

1. **Weekly Picks**: Each week, players must choose a Survivor contestant they believe will NOT be voted out
2. **No Repeats**: Players cannot choose the same contestant more than once throughout the season
3. **Elimination**: If a player's chosen contestant gets voted out, that player loses the game
4. **Scoring**: Player scores are calculated by how many contestants they can still choose from remaining active contestants
5. **Winner**: Last player with valid picks remaining wins the pool

## User Types

- **User**: All users have the same account type. Users can join pools, make picks, and create their own pools. Any user can create a pool and invite anybody on the app to join these pools. Pool creators have control over their own pools, including managing contestants and season progression for their pools.

## Data Requirements

### User Management

- User accounts with username, email, password authentication
- User profiles with display names and basic information
- Account status tracking (active/inactive)

### Pool Management

- Pool creation with names and season association (any user can create pools)
- Pool membership tracking
- Pool status management (active, completed)
- Pool creator permissions for managing their own pools

### Contestant Database

- Current season contestant roster
- Contestant status tracking (active, eliminated, winner)
- Elimination week tracking
- Tribe/alliance information

### Pick Tracking

- Weekly pick submissions by users
- Historical pick data for analysis
- Pick validation against game rules
- Pick results (safe, eliminated, pending)

### Scoring System

- Real-time leaderboard calculation
- Remaining choice counts per player
- Elimination tracking
- Historical performance data

## Frontend Requirements

### Authentication & User Management

- User registration and login system
- Password reset functionality
- User profile management

### Pool Interface

- Pool creation and joining workflow
- Pool member listing and management
- Pool-specific leaderboards
- Pool settings and configuration

### Game Play Interface

- Weekly pick submission form
- Contestant information display
- Pick deadline enforcement
- Pick confirmation and validation

### Analytics & History

- Personal pick history with results
- Pool performance analytics
- Contestant popularity statistics
- Historical data visualization

### Responsive Design

- Mobile-friendly interface for all screens
- Touch-optimized interactions
- Consistent experience across devices

## Backend Requirements

### Authentication System

- Secure user registration and login
- JWT-based session management
- Password security and validation
- Account verification processes

### Pool Management API

- Pool creation and configuration
- Member invitation and joining
- Pool status and settings management
- Permission-based access control

### Game Logic Engine

- Pick validation against rules
- Automatic scoring calculations
- Leaderboard generation
- Season progression handling

### Data Management

- Contestant database management
- Pick submission and storage
- Historical data preservation
- Real-time data synchronization

### Pool Creator Interface

- Contestant management for their pools (add/remove/update)
- Season setup and configuration for their pools
- Elimination processing for their pools
- Pool-specific monitoring and maintenance

## Technical Architecture

### Frontend Technology

- Flutter application for all platforms: web, iOS, Android, MacOS, Windows
- Main target is for mobile app and design
- Responsive, modern UI/UX design

### Backend Technology

- Python-based REST API
- JWT authentication system
- Comprehensive input validation
- Error handling and logging

### Database Design

- NoSQL document-based storage
- Efficient querying and indexing
- Data relationship management
- Backup and recovery systems

### Deployment Infrastructure

- Containerized application deployment
- Multi-service architecture
- Load balancing and scaling
- SSL security and encryption

## Development Phases

### Phase 1: Core Functionality

**Objective**: Launch MVP with essential game features

- User registration and authentication
- Basic pool creation and joining
- Weekly pick submissions
- Simple leaderboard display
- Pool creator contestant management

### Phase 2: Enhanced User Experience

**Objective**: Improve usability and add social features

- Advanced leaderboard with detailed statistics
- Pick history and performance tracking
- Improved UI/UX design
- Mobile optimization
- Email notifications for deadlines

### Phase 3: Advanced Features

**Objective**: Add unique features and mobile apps

- Custom challenge mechanics
- Bonus pick opportunities
- Advanced analytics and insights
- Native mobile applications
- Push notification system

## Success Metrics

- User engagement (daily/weekly active users)
- Pool completion rates
- Pick submission timing and patterns
- User retention across seasons
- System performance and reliability

## Future Enhancements

- Multi-season support
- Private pool customization options
- Social sharing and invitations
- Integration with Survivor episode schedules
- Advanced statistical analysis tools
- Tournament-style elimination formats

## Security & Privacy

- Secure password handling and storage
- User data privacy protection
- Secure API communication
- Input validation and sanitization
- Regular security updates and monitoring
