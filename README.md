# NFT-Based Access Control & Ticketing System

A comprehensive blockchain-based ticketing solution built on the Stacks blockchain using Clarity smart contracts. This system transforms traditional event ticketing by leveraging NFT technology to provide secure, transparent, and feature-rich ticket management.

## 🎯 Overview

This project implements a decentralized ticketing system where each ticket is represented as a unique NFT (Non-Fungible Token) on the Stacks blockchain. The system provides enhanced security, prevents fraud, enables royalties on resales, and offers post-event utility for ticket holders.

## ✨ Core Features

### 1. NFT Ticket Minting ✅
- **Unique NFT Tickets**: Each ticket is minted as a unique NFT with embedded metadata
- **Event Metadata**: Includes event-id, seat/zone information, and validity status
- **Organizer Control**: Event organizers can set supply limits, pricing, and royalty percentages
- **Direct Purchase**: Attendees can purchase tickets directly from the smart contract
- **SIP-009 Compliance**: Follows Stacks NFT standards for maximum compatibility

### 2. Dynamic Metadata System (Coming Soon)
- **Status Tracking**: Tickets transition from "Valid" to "Used" upon entry scanning
- **One-Time Access**: Contract enforces single-use validation to prevent re-entry
- **Anti-Fraud**: Prevents counterfeiting and screenshot-based fraud

### 3. Royalty System (Coming Soon)
- **Secondary Market**: Automatic royalty distribution on resales
- **Organizer Benefits**: Configurable percentage goes back to event organizers
- **Anti-Scalping**: Reduces scalper profitability while maintaining market liquidity

### 4. Extended Features (Roadmap)
- **Post-Event Utility**: NFTs transform into collectible memory assets
- **Exclusive Content**: Unlock recordings, behind-the-scenes content
- **Community Access**: Token-gated Discord/Telegram communities
- **Proof of Attendance**: POAP-style verification system

## 🏗️ Architecture

### Smart Contract Structure
\`\`\`
contracts/
├── ticket-nft.cty          # Main NFT ticket contract (Feature 1)
├── access-control.cty      # Entry validation system (Feature 2)
├── royalty-manager.cty     # Resale royalty handling (Feature 3)
└── event-manager.cty       # Event creation and management
\`\`\`

### Technology Stack
- **Blockchain**: Stacks (Bitcoin Layer 2)
- **Smart Contract Language**: Clarity
- **Development Tool**: Clarinet
- **NFT Standard**: SIP-009
- **Testing Framework**: Clarinet Test Suite

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks CLI](https://docs.stacks.co/docs/cli) for deployment
- Node.js 16+ for frontend development

### Installation

1. **Clone the repository**
   \`\`\`bash
   git clone https://github.com/your-org/nft-ticketing-system.git
   cd nft-ticketing-system
   \`\`\`

2. **Initialize Clarinet project**
   \`\`\`bash
   clarinet new nft-ticketing
   cd nft-ticketing
   \`\`\`

3. **Install dependencies**
   \`\`\`bash
   npm install
   \`\`\`

### Development Setup

1. **Start local blockchain**
   \`\`\`bash
   clarinet integrate
   \`\`\`

2. **Run tests**
   \`\`\`bash
   clarinet test
   \`\`\`

3. **Deploy to testnet**
   \`\`\`bash
   clarinet deploy --testnet
   \`\`\`

## 📋 Smart Contract API

### Feature 1: NFT Ticket Minting

#### Public Functions

**`create-event`**
```clarity
(create-event (event-name (string-ascii 50)) 
              (total-supply uint) 
              (ticket-price uint) 
              (royalty-percent uint))
