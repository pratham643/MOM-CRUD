# Current Payroll System vs Indian Darwinbox Payroll System - Detailed Comparison

**Report Date:** June 4, 2026  
**Project:** MOM HRMS India  
**Analysis Type:** Payroll System Gap Analysis  

---

## Executive Summary

This document provides a comprehensive comparison between the current MOM HRMS Payroll system and the Indian Darwinbox payroll system. The analysis covers payroll structure, statutory compliance, calculations, reports, and features.

**Overall Assessment:** The current system has a basic payroll foundation but lacks critical Indian statutory compliance features that Darwinbox provides out-of-the-box.

---

## 1. PAYROLL STRUCTURE COMPARISON

### 1.1 Earnings Components

| Component | Current MOM HRMS | Darwinbox India | Gap Status |
|-----------|----------------|-----------------|------------|
| Basic Salary | ✅ Supported | ✅ Supported | ✅ Match |
| HRA (House Rent Allowance) | ✅ Supported | ✅ Supported (40-50% of Basic) | ✅ Match |
| Special Allowance | ❌ Not explicit | ✅ Supported | ⚠️ Gap |
| Conveyance Allowance | ❌ Not supported | ✅ Supported (₹1,800-2,400/month) | ❌ Missing |
| Medical Allowance | ❌ Not supported | ✅ Supported | ❌ Missing |
| LTA (Leave Travel Allowance) | ❌ Not supported | ✅ Supported | ❌ Missing |
| Education Allowance | ❌ Not supported | ✅ Supported | ❌ Missing |
| Other Allowance | ✅ Supported | ✅ Supported | ✅ Match |

**Current Implementation:**
```php
// File: Modules/Payroll/Entities/UserSalary.php
protected $fillable = [
    'user_id', 'basic', 'hra', 'food_allowance', 
    'travel_allowance', 'other_allowance', 'gross',
    'total_working_days','fixed_allowances','fixed_deductions'
];
```

**Darwinbox Equivalent Structure:**
```
Earnings:
├── Basic (40-50% of CTC)
├── HRA (40% of Basic for metros, 30% for non-metros)
├── Special Allowance (balancing component)
├── Conveyance Allowance (₹1,800-2,400/month)
├── Medical Allowance (₹1,250/month or ₹15,000/year)
├── LTA (8.33% of Basic or fixed amount)
├── Education Allowance (₹100/child/month, max 2 children)
└── Other Allowances (flexible)
```

### 1.2 Deductions Components

| Component | Current MOM HRMS | Darwinbox India | Gap Status |
|-----------|----------------|-----------------|------------|
| PF (Provident Fund) | ❌ Not built-in | ✅ 12% of Basic | ❌ Missing |
| ESIC (Employee State Insurance) | ❌ Not supported | ✅ 0.75% (employee), 3.25% (employer) | ❌ Missing |
| Professional Tax | ❌ Not supported | ✅ State-based (₹0-200/month) | ❌ Missing |
| TDS (Tax Deducted at Source) | ⚠️ Basic tax support | ✅ Full income tax calculation | ⚠️ Partial |
| Loan Deduction | ✅ Supported | ✅ Supported | ✅ Match |
| Advance Salary | ✅ Supported | ✅ Supported | ✅ Match |
| Other Deductions | ✅ Supported | ✅ Supported | ✅ Match |

**Current Implementation:**
```php
// File: Modules/Payroll/Entities/UserDeduction.php
protected $fillable = [
    'user_id', 'title', 'deduction_type', 'amount', 
    'salary_id', 'percentage_amount', 'date', 'month_code', 
    'year', 'is_fixed_for_current_month', 'document_request_id', 
    'branch_id', 'remark',
];
```

---

## 2. STATUTORY COMPLIANCE COMPARISON

### 2.1 Provident Fund (PF) Management

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| PF Calculation (12% of Basic) | ❌ Not implemented | ✅ Auto-calculated | ❌ Missing |
| UAN (Universal Account Number) | ❌ Not stored | ✅ Stored and validated | ❌ Missing |
| PF Number Management | ❌ Not supported | ✅ Stored per employee | ❌ Missing |
| PF Contribution Split (EE/ER) | ❌ Not supported | ✅ Employee & Employer split | ❌ Missing |
| PF Wage Ceiling (₹15,000) | ❌ Not supported | ✅ Configurable | ❌ Missing |
| PF Reports (Form 3, 5, 10, 12A) | ❌ Not available | ✅ Auto-generated | ❌ Missing |
| PF Challan Generation | ❌ Not available | ✅ ECR generation | ❌ Missing |

**Current Tax Support:**
```php
// File: Modules/Payroll/Entities/EmployeeTax.php
protected $fillable = ['taxtype', 'taxunit', 'taxamount'];
// Only basic tax support, no PF-specific logic
```

### 2.2 ESIC (Employee State Insurance Corporation)

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| ESIC Calculation | ❌ Not implemented | ✅ 0.75% employee, 3.25% employer | ❌ Missing |
| ESIC Number Storage | ❌ Not supported | ✅ Stored per employee | ❌ Missing |
| ESIC Wage Limit (₹21,000) | ❌ Not supported | ✅ Configurable | ❌ Missing |
| ESIC Reports | ❌ Not available | ✅ Monthly returns | ❌ Missing |
| ESIC Challan | ❌ Not available | ✅ Auto-generated | ❌ Missing |

### 2.3 Professional Tax (PT)

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| PT Calculation | ❌ Not implemented | ✅ State-based slabs | ❌ Missing |
| PT Slab Configuration | ❌ Not supported | ✅ Per state configuration | ❌ Missing |
| PT Deduction Cap (₹2,500/year) | ❌ Not supported | ✅ Auto-capped | ❌ Missing |
| PT Reports | ❌ Not available | ✅ Monthly/Annual | ❌ Missing |

### 2.4 Income Tax (TDS)

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| Tax Regime Selection | ❌ Not supported | ✅ Old vs New regime | ❌ Missing |
| 80C Deductions | ❌ Not supported | ✅ Up to ₹1.5 lakhs | ❌ Missing |
| 80D (Medical Insurance) | ❌ Not supported | ✅ Up to ₹25,000-50,000 | ❌ Missing |
| HRA Exemption Calculation | ❌ Not supported | ✅ Auto-calculated | ❌ Missing |
| LTA Exemption | ❌ Not supported | ✅ Supported | ❌ Missing |
| Standard Deduction (₹50,000) | ❌ Not supported | ✅ Auto-applied | ❌ Missing |
| Form 16 Generation | ❌ Not available | ✅ Auto-generated | ❌ Missing |
| Investment Declaration | ❌ Not supported | ✅ Employee declarations | ❌ Missing |

**Current Tax Implementation:**
```php
// File: Modules/Payroll/Entities/EmployeeTaxUser.php
// Basic tax mapping, no Indian tax regime support
```

### 2.5 Gratuity

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| Gratuity Calculation | ⚠️ Basic support | ✅ (Basic+DA)×15/26×years | ⚠️ Partial |
| Payment of Gratuity Act | ⚠️ Partial | ✅ Full compliance | ⚠️ Partial |
| 5 Years Service Rule | ✅ Supported | ✅ Supported | ✅ Match |
| Gratuity Reports | ⚠️ Basic | ✅ Comprehensive | ⚠️ Partial |

**Current Gratuity Implementation:**
```php
// File: Modules/Payroll/Http/Controllers/UserPaySlipController.php
public function gratuity_report_download(Request $request)
{
    // Basic gratuity calculation exists
    $gratuity = $employee->calculateGratuity($chosenDate);
    // Returns: joining_date, based_date, basic_salary, totalamount
}
```

---

## 3. PAYROLL CALCULATION ENGINE

### 3.1 Salary Calculation Methods

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| Monthly Salary | ✅ Supported | ✅ Supported | ✅ Match |
| Daily Wage Calculation | ✅ Supported | ✅ Supported | ✅ Match |
| Hourly Rate Calculation | ✅ Supported | ✅ Supported | ✅ Match |
| Pro-rata Salary | ⚠️ Basic | ✅ Advanced | ⚠️ Partial |
| Arrears Calculation | ❌ Not supported | ✅ Supported | ❌ Missing |
| Recovery Calculation | ❌ Not supported | ✅ Supported | ❌ Missing |
| Loan Amortization | ⚠️ Basic | ✅ EMI-based | ⚠️ Partial |

**Current Calculation Logic:**
```php
// File: Modules/Payroll/Traits/SalaryCalculation.php

// Gross Salary Calculation
public function getGrossSalary($user, $month, $year, $start_date, $end_date)
{
    $basic_salary = $user->salary->basic ?? 0;
    $fixed_entity_allowance = 0; // From JSON
    
    // Missing: PF, ESIC, Professional Tax calculations
    $gross_salary = $basic_salary + $fixed_entity_allowance;
    return (float) round($gross_salary, 2);
}

// Net Salary Calculation
public function getTotalNetSalary($user, $month, $year, $start_date, $end_date)
{
    $attendanceBaseSalary = $this->getNetSalaryAsPerAttendance(...);
    $monthly_fixed = $this->monthlyfixedExpensesCalculation(...);
    $monthly_not_fixed = $this->monthlynotfixedExpensesCalculation(...);
    
    // Missing: Statutory deductions
    $total_net_salary = (($attendanceBaseSalary + $monthly_fixed_advance_loan) 
                         + $overtime_amount + $monthly_expense + $total_allowance) 
                        - ($total_deduction + $monthly_fixed_advance_salary);
    
    return round((float) $total_net_salary, $roundoff);
}
```

### 3.2 Attendance-Based Calculations

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| Paid Days Calculation | ✅ Supported | ✅ Supported | ✅ Match |
| Absent Days Deduction | ✅ Supported | ✅ Supported | ✅ Match |
| Leave Without Pay (LOP) | ✅ Supported | ✅ Supported | ✅ Match |
| Holiday Consideration | ✅ Supported | ✅ Supported | ✅ Match |
| Half-day Calculation | ✅ Supported | ✅ Supported | ✅ Match |
| Overtime Integration | ✅ Supported | ✅ Supported | ✅ Match |

---

## 4. PAYSLIP & REPORTS

### 4.1 Payslip Features

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| Digital Payslip | ✅ Supported | ✅ Supported | ✅ Match |
| PDF Generation | ✅ Supported | ✅ Supported | ✅ Match |
| Email Distribution | ✅ Supported | ✅ Supported | ✅ Match |
| Custom Templates | ⚠️ Limited | ✅ Multiple templates | ⚠️ Partial |
| Mobile View | ✅ Supported | ✅ Supported | ✅ Match |
| Payslip History | ✅ Supported | ✅ Supported | ✅ Match |
| Bulk Generation | ✅ Supported | ✅ Supported | ✅ Match |

**Current Payslip Model:**
```php
// File: Modules/Payroll/Entities/UserPaySlip.php
protected $fillable = [
    'user_id', 'slip_generation_date', 'month_code', 'year',
    'total_working_days', 'basic', 'hra', 'food_allowance', 
    'travel_allowance', 'other_allowance', 'gross', 'net_salary',
    'fixed_allowances', 'fixed_deductions', 'overtime_amount',
    'expense_amount', 'total_allowance', 'total_deduction',
    'total_overtime', 'total_net_salary', 'status', 'is_close',
    // ... additional fields
];
```

### 4.2 Reports Comparison

| Report | Current MOM HRMS | Darwinbox India | Gap Status |
|--------|----------------|-----------------|------------|
| Payslip Report | ✅ Available | ✅ Available | ✅ Match |
| Salary Register | ⚠️ Basic | ✅ Comprehensive | ⚠️ Partial |
| Gratuity Report | ✅ Available | ✅ Available | ✅ Match |
| PF Report | ❌ Not available | ✅ Form 3, 5, 10, 12A | ❌ Missing |
| ESIC Report | ❌ Not available | ✅ Monthly returns | ❌ Missing |
| PT Report | ❌ Not available | ✅ Monthly/Annual | ❌ Missing |
| TDS Report | ❌ Not available | ✅ Form 24Q, 16 | ❌ Missing |
| Investment Report | ❌ Not available | ✅ 80C, 80D etc | ❌ Missing |
| Settlement Report | ⚠️ Basic | ✅ Full & Final | ⚠️ Partial |
| Bank Advice | ❌ Not available | ✅ Available | ❌ Missing |
| Compliance Dashboard | ❌ Not available | ✅ Available | ❌ Missing |

---

## 5. ADVANCE & LOAN MANAGEMENT

### 5.1 Advance Salary

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| Advance Request | ✅ Supported | ✅ Supported | ✅ Match |
| Approval Workflow | ✅ Supported | ✅ Multi-level | ⚠️ Partial |
| EMI Calculation | ✅ Supported | ✅ Supported | ✅ Match |
| Recovery Tracking | ✅ Supported | ✅ Supported | ✅ Match |
| Interest Calculation | ❌ Not supported | ✅ Supported | ❌ Missing |

**Current Implementation:**
```php
// File: Modules/Payroll/Entities/AdvanceRequest.php
protected $fillable = [
    'reference_number', 'type', 'reason', 'amount', 'instalments',
    'start_month', 'status', 'approved_amount', 'loan_months',
    'installment_amount', 'installments_paid', 'installments_pending',
    'user_id', 'loan_mode', 'approved_date', 'rejected_date',
    'rejection_reason', 'requested_date',
];
```

### 5.2 Loan Management

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| Loan Types | ⚠️ Basic (Salary/Loan) | ✅ Multiple types | ⚠️ Partial |
| Loan Eligibility | ❌ Not supported | ✅ Rule-based | ❌ Missing |
| Interest Calculation | ❌ Not supported | ✅ Supported | ❌ Missing |
| Loan Schedule | ⚠️ Basic | ✅ Amortization | ⚠️ Partial |
| Pre-payment | ❌ Not supported | ✅ Supported | ❌ Missing |

---

## 6. POLICY & CONFIGURATION

### 6.1 Payroll Policies

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| Policy Configuration | ✅ Supported | ✅ Advanced | ⚠️ Partial |
| Formula Builder | ⚠️ Basic | ✅ Visual builder | ⚠️ Partial |
| Component Mapping | ⚠️ Limited | ✅ Comprehensive | ⚠️ Partial |
| Version Control | ❌ Not supported | ✅ Supported | ❌ Missing |
| Effective Dating | ⚠️ Basic | ✅ Advanced | ⚠️ Partial |

**Current Policy Implementation:**
```php
// File: Modules/Payroll/Entities/PayrollPolicy.php
protected $fillable = [
    'name', 'type', 'hourly_charges', 'max_hours_per_day', 
    'max_hours_per_month', 'formula', 'fixed_amount', 
    'min_hours_per_day', 'min_hours_per_month'
];

// File: Modules/PolicySetting/Entities/PolicySettings.php
protected $fillable = ['type', 'name', 'status', 'policy', 'description'];
// Stores JSON-based policy configuration
```

---

## 7. INTEGRATION CAPABILITIES

### 7.1 Attendance Integration

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| Attendance Sync | ✅ Supported | ✅ Real-time | ✅ Match |
| Leave Integration | ✅ Supported | ✅ Supported | ✅ Match |
| Overtime Calculation | ✅ Supported | ✅ Supported | ✅ Match |
| Shift Management | ✅ Supported | ✅ Supported | ✅ Match |

### 7.2 External Integrations

| Integration | Current MOM HRMS | Darwinbox India | Gap Status |
|-------------|----------------|-----------------|------------|
| Bank API | ❌ Not available | ✅ Salary transfer | ❌ Missing |
| PF Portal | ❌ Not available | ✅ ECR upload | ❌ Missing |
| ESIC Portal | ❌ Not available | ✅ Returns filing | ❌ Missing |
| Tax Portal | ❌ Not available | ✅ TDS filing | ❌ Missing |
| Accounting Software | ❌ Not available | ✅ Tally, SAP | ❌ Missing |

---

## 8. USER EXPERIENCE

### 8.1 Employee Self-Service

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| View Payslip | ✅ Supported | ✅ Supported | ✅ Match |
| Download Payslip | ✅ Supported | ✅ Supported | ✅ Match |
| Tax Declarations | ❌ Not supported | ✅ Supported | ❌ Missing |
| Investment Proof | ❌ Not supported | ✅ Supported | ❌ Missing |
| Loan Application | ✅ Supported | ✅ Supported | ✅ Match |
| Salary Breakdown | ⚠️ Basic | ✅ Detailed | ⚠️ Partial |

### 8.2 Admin Dashboard

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| Payroll Dashboard | ⚠️ Basic | ✅ Comprehensive | ⚠️ Partial |
| Bulk Operations | ✅ Supported | ✅ Supported | ✅ Match |
| Audit Trail | ⚠️ Basic | ✅ Detailed | ⚠️ Partial |
| Exception Handling | ⚠️ Basic | ✅ Advanced | ⚠️ Partial |
| Notifications | ✅ Supported | ✅ Supported | ✅ Match |

---

## 9. COMPLIANCE & AUDIT

### 9.1 Statutory Compliance

| Requirement | Current MOM HRMS | Darwinbox India | Gap Status |
|-------------|----------------|-----------------|------------|
| Minimum Wages Act | ❌ Not enforced | ✅ Configurable | ❌ Missing |
| Payment of Wages Act | ⚠️ Partial | ✅ Full compliance | ⚠️ Partial |
| Payment of Bonus Act | ❌ Not supported | ✅ Supported | ❌ Missing |
| Payment of Gratuity Act | ⚠️ Partial | ✅ Full compliance | ⚠️ Partial |
| EPF & MP Act | ❌ Not supported | ✅ Full compliance | ❌ Missing |
| ESI Act | ❌ Not supported | ✅ Full compliance | ❌ Missing |
| Professional Tax Act | ❌ Not supported | ✅ State-wise | ❌ Missing |
| Income Tax Act | ⚠️ Basic | ✅ Full compliance | ⚠️ Partial |

### 9.2 Audit & Security

| Feature | Current MOM HRMS | Darwinbox India | Gap Status |
|---------|----------------|-----------------|------------|
| Change Logs | ⚠️ Basic | ✅ Comprehensive | ⚠️ Partial |
| Data Encryption | ✅ Supported | ✅ Supported | ✅ Match |
| Role-based Access | ✅ Supported | ✅ Supported | ✅ Match |
| Data Backup | ⚠️ Manual | ✅ Automated | ⚠️ Partial |
| GDPR Compliance | ⚠️ Partial | ✅ Compliant | ⚠️ Partial |

---

## 10. GAP SUMMARY & PRIORITIZATION

### Critical Gaps (Must Have for Indian Compliance)

1. **Provident Fund (PF) Management**
   - PF calculation (12% of Basic)
   - UAN management
   - ECR generation
   - PF reports (Form 3, 5, 10, 12A)

2. **ESIC Management**
   - ESIC calculation (0.75% employee, 3.25% employer)
   - ESIC number storage
   - Monthly returns
   - Challan generation

3. **Professional Tax**
   - State-based PT slabs
   - PT calculation and deduction
   - PT reports

4. **Income Tax (TDS)**
   - Old vs New tax regime
   - 80C, 80D deductions
   - HRA exemption
   - Form 16 generation
   - Investment declarations

5. **Indian Payroll Components**
   - Conveyance Allowance
   - Medical Allowance
   - LTA
   - Education Allowance
   - Special Allowance

### High Priority Gaps

6. **Advanced Reports**
   - Salary Register with Indian components
   - Compliance dashboard
   - Bank advice
   - Settlement reports

7. **Policy Configuration**
   - Visual formula builder
   - Version control
   - Component mapping

8. **Integration**
   - Bank API for salary transfer
   - PF/ESIC portal integration
   - Accounting software integration

### Medium Priority Gaps

9. **Employee Self-Service**
   - Tax declarations
   - Investment proof submission
   - Detailed salary breakdown

10. **Admin Features**
    - Comprehensive audit trail
    - Exception handling
    - Automated backups

---

## 11. IMPLEMENTATION ROADMAP

### Phase 1: Core Indian Compliance (Weeks 1-4)
- [ ] Add PF calculation and management
- [ ] Add ESIC calculation and management
- [ ] Add Professional Tax calculation
- [ ] Update payroll structure with Indian components
- [ ] Create Indian document types (UAN, PAN, Aadhaar, ESIC)

### Phase 2: Tax Management (Weeks 5-8)
- [ ] Implement income tax calculation (Old & New regime)
- [ ] Add 80C, 80D deduction support
- [ ] Implement HRA exemption calculation
- [ ] Add investment declaration system
- [ ] Generate Form 16

### Phase 3: Reports & Compliance (Weeks 9-12)
- [ ] Create PF reports (Form 3, 5, 10, 12A, ECR)
- [ ] Create ESIC reports and returns
- [ ] Create PT reports
- [ ] Enhance salary register
- [ ] Create compliance dashboard

### Phase 4: Advanced Features (Weeks 13-16)
- [ ] Add bank API integration
- [ ] Implement policy configuration builder
- [ ] Add employee tax declaration portal
- [ ] Create settlement module
- [ ] Add advanced audit features

---

## 12. DATABASE SCHEMA CHANGES REQUIRED

### New Tables Needed

```sql
-- Provident Fund Configuration
CREATE TABLE pf_configurations (
    id BIGINT PRIMARY KEY,
    company_id BIGINT,
    pf_rate DECIMAL(5,2) DEFAULT 12.00,
    wage_ceiling DECIMAL(10,2) DEFAULT 15000.00,
    admin_charges DECIMAL(5,2) DEFAULT 0.65,
    edli_charges DECIMAL(5,2) DEFAULT 0.50,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- ESIC Configuration
CREATE TABLE esic_configurations (
    id BIGINT PRIMARY KEY,
    company_id BIGINT,
    employee_rate DECIMAL(5,2) DEFAULT 0.75,
    employer_rate DECIMAL(5,2) DEFAULT 3.25,
    wage_ceiling DECIMAL(10,2) DEFAULT 21000.00,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Professional Tax Slabs
CREATE TABLE professional_tax_slabs (
    id BIGINT PRIMARY KEY,
    state VARCHAR(50),
    min_salary DECIMAL(10,2),
    max_salary DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Tax Regime Configuration
CREATE TABLE tax_regimes (
    id BIGINT PRIMARY KEY,
    name VARCHAR(100), -- 'Old', 'New'
    financial_year VARCHAR(9), -- '2025-2026'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Tax Slabs
CREATE TABLE tax_slabs (
    id BIGINT PRIMARY KEY,
    regime_id BIGINT,
    min_income DECIMAL(12,2),
    max_income DECIMAL(12,2),
    tax_rate DECIMAL(5,2),
    rebate DECIMAL(12,2) DEFAULT 0,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Employee Tax Declarations
CREATE TABLE employee_tax_declarations (
    id BIGINT PRIMARY KEY,
    user_id BIGINT,
    financial_year VARCHAR(9),
    regime_choice VARCHAR(20), -- 'old' or 'new'
    section_80c_amount DECIMAL(12,2) DEFAULT 0,
    section_80d_amount DECIMAL(12,2) DEFAULT 0,
    hra_exemption DECIMAL(12,2) DEFAULT 0,
    lta_exemption DECIMAL(12,2) DEFAULT 0,
    standard_deduction DECIMAL(12,2) DEFAULT 50000,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### Table Modifications

```sql
-- Add Indian payroll columns to user_salaries
ALTER TABLE user_salaries ADD COLUMN (
    conveyance_allowance DECIMAL(10,2) DEFAULT 0,
    medical_allowance DECIMAL(10,2) DEFAULT 0,
    lta_allowance DECIMAL(10,2) DEFAULT 0,
    education_allowance DECIMAL(10,2) DEFAULT 0,
    special_allowance DECIMAL(10,2) DEFAULT 0,
    pf_deduction DECIMAL(10,2) DEFAULT 0,
    esic_deduction DECIMAL(10,2) DEFAULT 0,
    professional_tax DECIMAL(10,2) DEFAULT 0,
    tds_deduction DECIMAL(10,2) DEFAULT 0
);

-- Add Indian identification fields to user_profiles
ALTER TABLE user_profiles ADD COLUMN (
    aadhaar_number VARCHAR(12),
    pan_number VARCHAR(10),
    uan_number VARCHAR(12),
    esic_number VARCHAR(17),
    pf_number VARCHAR(20),
    ifsc_code VARCHAR(11),
    bank_account_number VARCHAR(20),
    bank_name VARCHAR(100)
);
```

---

## 13. CONCLUSION

The current MOM HRMS Payroll system provides a solid foundation with basic salary management, allowance/deduction handling, and payslip generation. However, to match Darwinbox's Indian payroll capabilities, significant enhancements are required in:

1. **Statutory Compliance** - PF, ESIC, Professional Tax, TDS
2. **Indian Payroll Components** - Conveyance, Medical, LTA, Education allowances
3. **Tax Management** - Old/New regime, deductions, exemptions
4. **Reports** - Compliance reports, Form 16, ECR generation
5. **Integrations** - Bank, PF/ESIC portals, accounting software

**Estimated Effort:** 16 weeks with a team of 3-4 developers
**Priority:** Focus on Phase 1 (Core Compliance) for immediate Indian market readiness

---

*Document Version: 1.0*  
*Last Updated: June 4, 2026*  
*Prepared by: Cline AI Analysis*
