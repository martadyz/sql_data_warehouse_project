/* usage: exec silver.load_silver;*/
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME

	BEGIN TRY
		PRINT '==========================================';
        PRINT 'Loading the silver layer';
        PRINT '==========================================';

        PRINT '-----------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '-----------------------------------------------';

		DECLARE @batch_start_time DATETIME = GETDATE();

		-- CRM_CUST_INFO
		print '>> Truncation table: silver.crm_cust_info'
		truncate table silver.crm_cust_info;
		print '>> Inserting data into table: silver.crm_cust_info'
		INSERT INTO silver.crm_cust_info (
		cst_id, cst_key, cst_firstname, cst_lastname, cst_create_date, cst_marital_status, cst_gndr
		)
		SELECT cst_id, cst_key, TRIM(cst_firstname) AS cst_firstname, TRIM(cst_lastname) AS cst_lastname, 
		cst_create_date,
		CASE 
			WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single' 
			WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married' 
			ELSE 'n/a' 
		END cst_marital_status,
		CASE 
			WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' 
			WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' 
			ELSE 'n/a' 
		END cst_gndr
		FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) 
		as flag_last 
		FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL)t WHERE flag_last = 1;

		-- CRM_PRD_INFO
		print '>> Truncation table: silver.crm_prd_info'
		truncate table silver.crm_prd_info;
		print '>> Inserting data into table: silver.crm_prd_info'
		insert into silver.crm_prd_info (
		prd_id, cat_id, prd_key, prd_line, prd_nm, prd_cost, prd_start_dt, prd_end_dt
		)
		SELECT 
		prd_id,
		REPLACE(SUBSTRING(prd_key,1, 5), '-', '_') as cat_id,
		substring(prd_key, 7, len(prd_key)) as prd_key,
		case upper(trim(prd_line))
			when 'M' then 'Mountain'
			when 'R' then 'Road'
			when 'S' then 'Other Sales'
			when 'T' then 'Touring'
			else 'n/a'
			end as prd_line,
		prd_nm, 
		ISNULL(prd_cost, 0) as prd_cost,
		cast (prd_start_dt as date) as prd_start_dt,
		cast(DATEADD(
				DAY,
				-1,
				lead(prd_start_dt) over (partition by prd_key order by prd_start_dt) 
			)as DATE) as prd_end_dt
		FROM bronze.crm_prd_info where SUBSTRING(prd_key, 7, len(prd_key)) IN (
		select sls_prd_key from bronze.crm_sales_details)

		-- CRM_SALES_DETAILS
		print '>> Truncation table: silver.crm_sales_details'
		truncate table silver.crm_sales_details;
		print '>> Inserting data into table: silver.crm_sales_details'

		insert into silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		) 
		select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		case 
			when sls_order_dt = 0 or len(sls_order_dt) != 8 
			then null
			else cast(cast(sls_order_dt as varchar) as date)
		end as sls_order_dt,
		case 
			when sls_ship_dt = 0 or len(sls_ship_dt) != 8 
			then null
			else cast(cast(sls_ship_dt as varchar) as date)
		end as sls_ship_dt,
		case 
			when sls_due_dt = 0 or len(sls_due_dt) != 8 
			then null
			else cast(cast(sls_due_dt as varchar) as date)
		end as sls_due_dt,
		case when sls_sales is null or sls_sales <=0 or sls_sales != sls_quantity * ABS(sls_price) 
		then sls_quantity * ABS(sls_price)
		else sls_sales
		end as sls_sales,
		sls_quantity,
		case when sls_price is null or sls_price <= 0
		then sls_sales / nullif(sls_quantity,0)
		else sls_price
		end as sls_price
		from bronze.crm_sales_details

		PRINT '-----------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '-----------------------------------------------';

		-- ERP_CUST_AZ12
		print '>> Truncation table: silver.erp_cust_az12'
		truncate table silver.erp_cust_az12;
		print '>> Inserting data into table: silver.erp_cust_az12'
		insert into silver.erp_cust_az12 (
		cid,
		bdate,
		gen
		)
		select 
		case when cid like 'NAS%' then  SUBSTRING(cid, 4, len(cid))
		else cid
		end  as cid,
		case when bdate > GETDATE() then null else bdate end as bdate,
		case 
			when upper(trim(gen)) in ('F', 'FEMALE') then 'Female'
			when upper(trim(gen)) in ('M', 'MALE') then 'Male'
			else 'n/a'
			end as gen
		from bronze.erp_cust_az12;


		-- ERP_LOC_A101
		print '>> Truncation table: silver.erp_loc_a101'
		truncate table silver.erp_loc_a101;
		print '>> Inserting data into table: silver.erp_loc_a101'
		insert into silver.erp_loc_a101 (
		cid, cntry
		)
		select 
		REPLACE(cid, '-', ''),
		case 
			when trim(cntry) = 'DE' then 'Germany'
			when trim(cntry) in ('US', 'USA') then 'United States'
			when trim(cntry) = '' or cntry is null then 'n/a'
			else trim(cntry)
			end as cntry
		from bronze.erp_loc_a101;

		-- ERP_PX_CAT_G1V2
		print '>> Truncation table: silver.erp_px_cat_g1v2'
		truncate table silver.erp_px_cat_g1v2;
		print '>> Inserting data into table: silver.erp_px_cat_g1v2'

		insert into silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
		select id, cat, subcat, maintenance from bronze.erp_px_cat_g1v2;

		DECLARE @batch_end_time DATETIME = GETDATE();
        PRINT '>> Duration WHOLE BATCH: ' + CONVERT(VARCHAR, DATEDIFF(SECOND, @batch_start_time, @batch_end_time)) + ' seconds';


        PRINT '==========================================';
        PRINT 'Loading completed successfully';
        PRINT '==========================================';

	END TRY
	BEGIN CATCH
        PRINT '===============================';
        PRINT 'error occured during loading silver layer';
        PRINT 'Error message' + ERROR_MESSAGE();
        PRINT 'Error number' + CAST (ERROR_NUMBER() AS NVARCHAR);
        PRINT '===============================';
    END CATCH
END
