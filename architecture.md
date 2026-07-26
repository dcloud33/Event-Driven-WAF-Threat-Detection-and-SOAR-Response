# Architecture Diagram

```mermaid
flowchart TD
    A[Test HTTP Requests] --> B[API Gateway]
    B --> C[AWS WAF]
    C --> D[WAF Analyzer Lambda]
    D --> E[DynamoDB: waf-events]
    E --> F[Correlation Lambda]
    F --> G[DynamoDB: waf-correlation-findings]
    G --> H[DynamoDB Stream]
    H --> I[EventBridge Pipe]
    I --> J[Default Event Bus]

    J --> K[MEDIUM/HIGH Rule]
    K --> L[SOAR Response Lambda]

    J --> M[CRITICAL Rule]
    M --> L
    M --> N[Critical Alert SNS]

    L --> O[DynamoDB: security-incidents]

    P[EventBridge Schedule] --> Q[Executive Reporting Lambda]
    Q --> R[S3: executive-reports/]
```