/*
Healthcare Payer Analytics Pipeline
v0.1 database foundation

Run manually in SSMS first.
*/

IF DB_ID(N'HealthcarePayerAnalytics') IS NULL
BEGIN
    CREATE DATABASE HealthcarePayerAnalytics;
END;
GO

USE HealthcarePayerAnalytics;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'raw')
    EXEC('CREATE SCHEMA raw');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'core')
    EXEC('CREATE SCHEMA core');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ref')
    EXEC('CREATE SCHEMA ref');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'measure')
    EXEC('CREATE SCHEMA measure');
GO
