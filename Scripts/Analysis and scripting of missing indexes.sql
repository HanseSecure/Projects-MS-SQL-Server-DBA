declare @rows intq100  --Record number of entries in table > q 1000 - Novice BD (FortisDataStore), 5000 - Trucks BD
declare @user_seeks intq100  --custom hits to the table > q 1000 - Beginner BD (FortisDataStore), 10,000 - BD Trucks
declare @avg_user_impact float=90. 0  -- % of possible improvement in >
--avg_user_impact<@avg_user_impact, but still a high rate of @est_impact
declare @dop_avg_user_impact float=15. 0
declare @est_impact intq1000 -- earlier values of 1,000,000 (BD Trucks), other BDs as of 100,000 
declare @max_new intq3--maximum of new indices per table
declare @last_seek intq3--at least three days
 
SELECT *
FROM
(SELECT  @@ServerName AS ServerName ,
        DB_NAME() AS DBName ,
        s. name+'.' +t. name AS  'Affected_table' ,
        row_number() over (partition by s. name+'.' +t. name order by (ddmigs. user_seeks+ddmigs. user_scans) *ddmigs. avg_user_impact DESC) Rang,
        COALESCE(ddmid. equality_columns, '')
        + CASE WHEN ddmid. equality_columns IS NOT NULL
                    AND ddmid. inequality_columns IS NOT NULL THEN  ','
               ELSE ''
          END + COALESCE(ddmid. inequality_columns,  '') AS Keys ,
        COALESCE(ddmid. included_columns,  '') AS [include] ,
 ddmid. [statement] ,
         'Create NonClustered Index IX_' + t. name+'_'+ CONVERT(varchar(8),getdate(),112)+'_'+ cast(row_number() over (partition by s. name+'.' +t. name order by (ddmigs. user_seeks+ddmigs. user_scans) *ddmigs. avg_user_impact DESC) as varchar(5))
        --+ CAST(ddmid.index_handle AS VARCHAR(20))
        +  ' On ' + ddmid. [statement] COLLATE database_default
        + ' (' + ISNULL(ddmid. equality_columns, '')
        + CASE WHEN ddmid. equality_columns IS NOT NULL
                    AND ddmid. inequality_columns IS NOT NULL THEN  ','
               ELSE ''
          END + ISNULL(ddmid. inequality_columns, '') + ')'
        + ISNULL(' Include (' + ddmid. included_columns +  ');', ';')
                                                  AS sql_statement ,
        ddmigs. user_seeks ,
        last_user_seek,
        last_user_scan,
        ind. Rows,
        CAST(( ddmigs. user_seeks + ddmigs. user_scans )
        * ddmigs. avg_user_impact AS BIGINT) AS  'est_impact',
        avg_user_impact
FROM sys. dm_db_missing_index_groups ddmig
        INNER JOIN sys. dm_db_missing_index_group_stats ddmigs
               ON ddmigs. group_handle = ddmig. index_group_handle
        INNER JOIN sys. dm_db_missing_index_details ddmid
               ON ddmig. index_handle = ddmid. index_handle
        INNER JOIN sys. tables t ON ddmid. OBJECT_ID = t. OBJECT_ID
        INNER JOIN sys. schemas s on(t. schema_id=s. schema_id)
        INNER JOIN
        (SELECT  --Indices, tables, table records
        OBJECT_SCHEMA_NAME(p. object_id)+'.' +OBJECT_NAME(p. object_id) AS TableName ,
        SUM(p. Rows) AS Rows
FROM sys. partitions p
        JOIN sys. indexes i ON i. object_id = p. object_id
                              AND i. index_id = p. index_id
WHERE i. type_desc IN  ('CLUSTERED',  'HEAP')  -- HEAP - heap, no key; CLUSTERED - usually the primary key
        AND OBJECT_SCHEMA_NAME(p. object_id)<>   'sys'  --choose non-system tables
GROUP BY p. object_id ,
        i. type_desc ,
        i. Name
HAVING SUM(p. Rows)> q@rows/ qmore than the specified number of entries q/) as ind on (s. name+'.' +t. name=ind. TableName)
WHERE ddmid. database_id = DB_ID()
    and ddmigs. user_seeks> @user_seeks  --the number of user searches
    and (avg_user_impact> @avg_user_impact  -- > the percentage of improvement
     or (avg_user_impact>=@dop_avg_user_impact and ((ddmigs. user_seeks + ddmigs. user_scans) *ddmigs. avg_user_impact) >=@est_impact)
     or CAST(( ddmigs. user_seeks + ddmigs. user_scans ) * ddmigs. avg_user_impact AS BIGINT)>=@est_impact*10)
) as a  -an indicator of possible improvement
WHERE Rang<=@max_new
  and (
        cast(last_user_seek AS DATE)>=dateadd(DAY,-@last_seek,cast(getdate() AS DATE))
     or cast(last_user_scan AS DATE)>=dateadd(DAY,-@last_seek,cast(getdate() AS DATE))
  )
ORDER BY [Rows],
         user_seeks DESC,
         Affected_table,
 est_impact DESC;  --Initially, the basic example states that est_impact the most important parameter to improve
