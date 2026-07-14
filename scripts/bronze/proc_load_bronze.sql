/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.
usage: EXEC bronze.load_bronze;
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
DECLARE @start_time DATETIME, @end_time DATETIME
   BEGIN TRY
        PRINT '==========================================';
        PRINT 'Loading the bronze layer';
        PRINT '==========================================';

        PRINT '-----------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '-----------------------------------------------';
        DECLARE @batch_start_time DATETIME = GETDATE();

        -- CRM_CUST_INFO
        DECLARE @start_time_cust DATETIME = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;
        PRINT '>> Inserting Table: bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info 
        FROM 'C:\Users\hpStart\Documents\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        DECLARE @end_time_cust DATETIME = GETDATE();
        PRINT '>> Duration: ' + CONVERT(VARCHAR, DATEDIFF(SECOND, @start_time_cust, @end_time_cust)) + ' seconds';

        -- CRM_PRD_INFO
        DECLARE @start_time_prd DATETIME = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;
        PRINT '>> Inserting Table: bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info 
        FROM 'C:\Users\hpStart\Documents\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        DECLARE @end_time_prd DATETIME = GETDATE();
        PRINT '>> Duration: ' + CONVERT(VARCHAR, DATEDIFF(SECOND, @start_time_prd, @end_time_prd)) + ' seconds';

        -- CRM_SALES_DETAILS
        DECLARE @start_time_sales DATETIME = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;
        PRINT '>> Inserting Table: bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details 
        FROM 'C:\Users\hpStart\Documents\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        DECLARE @end_time_sales DATETIME = GETDATE();
        PRINT '>> Duration: ' + CONVERT(VARCHAR, DATEDIFF(SECOND, @start_time_sales, @end_time_sales)) + ' seconds';

        PRINT '-----------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '-----------------------------------------------';

        -- ERP_CUST_AZ12
        DECLARE @start_time_erp_cust DATETIME = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;
        PRINT '>> Inserting Table: bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12 
        FROM 'C:\Users\hpStart\Documents\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        DECLARE @end_time_erp_cust DATETIME = GETDATE();
        PRINT '>> Duration: ' + CONVERT(VARCHAR, DATEDIFF(SECOND, @start_time_erp_cust, @end_time_erp_cust)) + ' seconds';

        -- ERP_LOC_A101
        DECLARE @start_time_loc DATETIME = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;
        PRINT '>> Inserting Table: bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101 
        FROM 'C:\Users\hpStart\Documents\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        DECLARE @end_time_loc DATETIME = GETDATE();
        PRINT '>> Duration: ' + CONVERT(VARCHAR, DATEDIFF(SECOND, @start_time_loc, @end_time_loc)) + ' seconds';

        -- ERP_PX_CAT_G1V2
        DECLARE @start_time_cat DATETIME = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        PRINT '>> Inserting Table: bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2 
        FROM 'C:\Users\hpStart\Documents\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        DECLARE @end_time_cat DATETIME = GETDATE();
        PRINT '>> Duration: ' + CONVERT(VARCHAR, DATEDIFF(SECOND, @start_time_cat, @end_time_cat)) + ' seconds';

        DECLARE @batch_end_time DATETIME = GETDATE();
        PRINT '>> Duration WHOLE BATCH: ' + CONVERT(VARCHAR, DATEDIFF(SECOND, @batch_start_time, @batch_end_time)) + ' seconds';


        PRINT '==========================================';
        PRINT 'Loading completed successfully';
        PRINT '==========================================';
    END TRY
    BEGIN CATCH
        PRINT '===============================';
        PRINT 'error occured during loading bronze layer';
        PRINT 'Error message' + ERROR_MESSAGE();
        PRINT 'Error number' + CAST (ERROR_NUMBER() AS NVARCHAR);
        PRINT '===============================';
    END CATCH
END
