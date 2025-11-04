# MediVault: Decentralized Medical Records Access Control

A Clarity smart contract for secure, transparent management of medical records access on the Stacks blockchain.

## Overview

MediVault provides a decentralized solution for managing medical record access between patients and healthcare providers. The system ensures privacy, security, and complete audit traceability of medical record access permissions.

## Features

- **Patient Control**: Patients maintain full ownership of their medical profiles
- **Provider Certification**: Official healthcare providers are certified by a trusted steward
- **Access Management**: Granular control over provider access permissions
- **Audit Trail**: Complete logging of all access grants and revocations
- **Steward Oversight**: Administrative control for provider certification

## Contract Functions

### Patient Operations
- `create-medical-profile`: Create a new medical profile
- `update-medical-profile`: Update existing profile
- `authorize-provider`: Grant access to a provider
- `revoke-authorization`: Revoke provider access

### Provider Operations
- Access to authorized patient records
- Certification status verification

### Administrative Functions
- `initialize-steward`: Set up contract administrator
- `certify-provider`: Certify healthcare providers
- `decertify-provider`: Remove provider certification
- `transfer-steward`: Transfer administrative rights

## Error Codes

| Code | Description |
|------|-------------|
| `MV-ERR-NOT-FOUND` | Requested resource not found |
| `MV-ERR-UNAUTHORIZED` | Unauthorized access attempt |
| `MV-ERR-ALREADY` | Resource already exists |
| `MV-ERR-NOT-CERTIFIED` | Provider not certified |
| `MV-ERR-NOT-OWNER` | Not the resource owner |
| `MV-ERR-NO-PROFILE` | Profile doesn't exist |

## Development

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet)
- [Stacks CLI](https://docs.stacks.co/references/stacks-cli)

### Testing
```bash
clarinet test
```

### Deployment
```bash
clarinet deploy
```

## Security

- Role-based access control
- Principal-based authentication
- Strict input validation
- Comprehensive error handling

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Authors

- Muhammad Miftahu

## Acknowledgments

- Stacks Foundation
- Clarity Lang Community
- Healthcare Privacy Advocates

---
For more information about Stacks smart contracts, visit [Stacks Documentation](https://docs.stacks.co).
