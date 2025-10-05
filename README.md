# Clarity Agreement

A Clarity smart contract system for managing two-party agreements where only principals can change decisions or transfer party control.

## Overview

The Clarity Agreement system consists of two main smart contracts that work together to provide a secure and transparent framework for managing agreements between two parties:

1. **Agreement Manager** - Manages agreement state and tracks party decisions
2. **Principal Controller** - Enforces principal-only access for decision changes and transfers

## Features

### Agreement Manager Contract
- Create new agreements between two parties
- Record party decisions on agreements
- Track agreement state and finalization
- Maintain history of all agreement interactions
- Support for agreement metadata and descriptions

### Principal Controller Contract
- Register principals with metadata
- Transfer principal control between addresses
- Delegate permissions to other principals with expiration
- Revoke delegated permissions
- Enforce principal-only access controls

## Architecture

```
┌─────────────────────┐    ┌─────────────────────┐
│  Agreement Manager  │    │ Principal Controller│
│                     │    │                     │
│ - Create Agreement  │    │ - Register Principal│
│ - Record Decision   │    │ - Transfer Control  │
│ - Finalize Agreement│    │ - Delegate Perms    │
│ - Track State       │    │ - Access Control    │
└─────────────────────┘    └─────────────────────┘
```

## Contract Functions

### Agreement Manager

#### Public Functions
- `create-agreement(party-a, party-b, agreement-data)` - Create new agreement
- `record-decision(agreement-id, decision)` - Record a party's decision
- `finalize-agreement(agreement-id)` - Finalize agreement when both parties decided

#### Read-Only Functions
- `get-agreement(agreement-id)` - Get agreement details
- `get-party-agreements(party)` - Get all agreements for a party
- `is-agreement-complete(agreement-id)` - Check if both parties decided
- `get-agreement-counter()` - Get total number of agreements

### Principal Controller

#### Public Functions
- `register-principal(metadata)` - Register as a principal
- `transfer-principal-control(new-principal, principal-id)` - Transfer control
- `delegate-permissions(delegatee, can-decide, can-transfer, expires-at)` - Delegate permissions
- `revoke-delegation(delegatee)` - Revoke delegated permissions
- `deactivate-principal(principal-id)` - Deactivate a principal

#### Read-Only Functions
- `is-registered-principal(principal-address)` - Check if registered
- `can-make-decisions(principal, target)` - Check decision permissions
- `can-transfer-control(principal, target)` - Check transfer permissions
- `get-principal(principal-id)` - Get principal details
- `get-principal-id(principal-address)` - Get principal ID by address
- `get-delegation(delegator, delegatee)` - Get delegation info

## Getting Started

### Prerequisites
- [Clarinet](https://docs.hiro.so/stacks/clarinet) - Clarity development environment
- Node.js and npm - For running tests

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd clarity-agreement
```

2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Creating an Agreement

```clarity
;; Create an agreement between two parties
(contract-call? .agreement-manager create-agreement 
  'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE 
  'SP2HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE 
  "Service Agreement for Web Development")
```

### Recording a Decision

```clarity
;; Party A records their decision (true = agree, false = disagree)
(contract-call? .agreement-manager record-decision u1 true)
```

### Registering as a Principal

```clarity
;; Register as a principal with metadata
(contract-call? .principal-controller register-principal "Lead Developer")
```

### Delegating Permissions

```clarity
;; Delegate decision-making permissions (expires in 144 blocks ~1 day)
(contract-call? .principal-controller delegate-permissions
  'SP2HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE
  true   ;; can make decisions
  false  ;; cannot transfer control
  (some (+ block-height u144)))
```

## Error Codes

### Agreement Manager
- `u100` - Unauthorized
- `u101` - Agreement not found
- `u102` - Invalid party
- `u103` - Agreement already exists
- `u104` - Agreement finalized
- `u105` - Party A decision missing
- `u106` - Party B decision missing

### Principal Controller
- `u200` - Unauthorized
- `u201` - Principal not found
- `u202` - Invalid principal
- `u203` - Transfer to self
- `u204` - Principal already exists

## Development

### Project Structure
```
clarity-agreement/
├── contracts/
│   ├── agreement-manager.clar
│   └── principal-controller.clar
├── tests/
│   ├── agreement-manager.test.ts
│   └── principal-controller.test.ts
├── settings/
│   ├── Devnet.toml
│   ├── Testnet.toml
│   └── Mainnet.toml
├── Clarinet.toml
└── README.md
```

### Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npx vitest tests/agreement-manager.test.ts

# Run tests in watch mode
npx vitest --watch
```

### Deployment

The contracts can be deployed to different networks using Clarinet:

```bash
# Deploy to devnet
clarinet publish --devnet

# Deploy to testnet
clarinet publish --testnet

# Deploy to mainnet
clarinet publish --mainnet
```

## Security Considerations

1. **Principal Verification** - Only registered principals can perform sensitive operations
2. **Permission Delegation** - Delegated permissions have expiration dates
3. **Access Control** - Strong validation ensures only authorized parties can modify agreements
4. **State Management** - Agreement finalization prevents further modifications
5. **Transfer Restrictions** - Principals cannot transfer control to themselves

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`npm test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Review the [Clarity documentation](https://docs.stacks.co/clarity/)
- Check the [Clarinet documentation](https://docs.hiro.so/clarinet/)