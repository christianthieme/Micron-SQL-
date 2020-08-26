create table #cross_join  (
[Fiscal_Month_YYYYMM] int
,[Business_Unit] varchar(20)
		,[DID] varchar(50)
      ,[Technology] varchar(50)
      ,[Architecture] varchar(50)
      ,[Series] varchar(50)
      ,[Channel] varchar(100)
      ,[Inventory_Area] varchar(100)
      ,[Metrics] varchar(100)
      ,[Units] varchar(50));

create table #b_data (
    [Export_Date] varchar(15)
      ,[Export_Time] varchar(15)
      ,[Business_Unit] varchar(20)
      ,[Year] varchar(10)
      ,[Quarter] varchar(10)
      ,[Month] varchar(10)
      ,[Fiscal_Period] int
	  ,[Fiscal_Month_Index] int
      ,Fiscal_Period_Digit int
      ,[Fiscal_Month_YYYYMM] int
	  , Prior_Month_Index int
	  ,Two_Prior_Month_Index int
	  , Prior_Qtr_Index int
	  ,[DID] varchar(50)
      ,[Technology] varchar(50)
      ,[Architecture] varchar(50)
      ,[Series] varchar(50)
      ,[Channel] varchar(100)
      ,[Inventory_Area] varchar(100)
      ,[Metrics] varchar(100)
      ,[Units] varchar(50)
	  ,[Value] float
	  ,Prior_Month int
	  ,Two_Prior__Month int
	  ,Prior_Qtr int
);

WITH date_table as (

SELECT
	[Fiscal_Month_YYYYMM] 
FROM [fin_tm1_cube_publishes].[dbo].[v_D_Month]
WHERE [Fiscal_Month_YYYYMM] > 201906 
  AND [Fiscal_Month_YYYYMM] < 202103  
  ),

data_table as (
SELECT DISTINCT 
Business_Unit,
		[DID]
      ,[Technology]
      ,[Architecture]
      ,[Series]
      ,[Channel]
      ,[Inventory_Area]
      ,[Metrics]
      ,[Units]
FROM [v_bu_inventory]
WHERE Metrics IN ('COGS', 'Ending Inventory Dollars', 'Ending Inventory Units')
)

INSERT INTO #cross_join 
SELECT * FROM date_table
CROSS JOIN data_table;

WITH bu_data as (

SELECT  vbui.[Export_Date]
      ,vbui.[Export_Time]
      ,vbui.[Business_Unit]
      ,vbui.[Year]
      ,vbui.[Quarter]
      ,vbui.[Month]
      ,vbui.[Fiscal_Period]
	  ,vdm.[Fiscal_Month_Index]
      ,vdm.[Fiscal_Period] as Fiscal_Period_Digit
      ,vdm.[Fiscal_Month_YYYYMM]
	  ,(SELECT Fiscal_Month_Index + 1
	  FROM [dbo].[v_D_Month] dmonth
	  WHERE vbui.Fiscal_Period = dmonth.Fiscal_Month_YYYYMM ) as Prior_Month_Index
	  ,(SELECT Fiscal_Month_Index + 2
	  FROM [dbo].[v_D_Month] dmonth
	  WHERE vbui.Fiscal_Period = dmonth.Fiscal_Month_YYYYMM ) as Two_Prior_Month_Index
	  , (SELECT Fiscal_Month_Index + 3
	  FROM [dbo].[v_D_Month] dmonth
	  WHERE vbui.Fiscal_Period = dmonth.Fiscal_Month_YYYYMM ) as Prior_Qtr_Index
	   ,vbui.[DID]
      ,vbui.[Technology]
     ,vbui.[Architecture]
     ,vbui.[Series]
    ,vbui.[Channel]
     ,vbui.[Inventory_Area]
     ,vbui.[Metrics]
     ,vbui.[Units]
	  ,vbui.[Value]
  FROM [fin_tm1_cube_publishes].[dbo].[v_bu_inventory] vbui
  LEFT JOIN [dbo].[v_D_Month] vdm ON vbui.Month = vdm.Fiscal_Month
  WHERE vbui.[Fiscal_Period] >= 201906
  AND vbui.Metrics IN ('COGS', 'Ending Inventory Dollars', 'Ending Inventory Units')
   ),

  b_data as (

  SELECT bd.*, 
  dm.[Fiscal_Month_YYYYMM] as Prior_Month
  ,dmt.[Fiscal_Month_YYYYMM] as Two_Prior__Month
  ,m.[Fiscal_Month_YYYYMM] as Prior_Qtr
  FROM bu_data bd
  LEFT JOIN [dbo].[v_D_Month] dm ON bd.Prior_Month_Index = dm.Fiscal_Month_Index
  LEFT JOIN [dbo].[v_D_Month] dmt ON bd.Two_Prior_Month_Index = dmt.Fiscal_Month_Index
  LEFT JOIN [dbo].[v_D_Month] m ON bd.Prior_Qtr_Index = m.Fiscal_Month_Index
  )
  
INSERT INTO #b_data
SELECT * FROM b_data


SELECT 
	cj.*,
	dm.[Fiscal_Month] as f_month,
    dm.[Fiscal_Quarter],
    dm.[Fiscal_Year],
	bd.Value as Value,
	bd_one.Value as Prior_Month_Value,
	bd_two.Value as Two_Prior_Month_Value,
	bd_three.Value as Prior_Qtr_Value,
	(COALESCE(bd.Value,0) + COALESCE(bd_one.Value,0) + COALESCE(bd_two.Value,0)) as Rolling_Qtr

FROM #cross_join  cj
LEFT JOIN #b_data bd ON cj.Fiscal_Month_YYYYMM = bd.Fiscal_Month_YYYYMM
	AND cj.Business_Unit = bd.Business_Unit
	AND cj.DID = bd.DID 
	AND cj.Technology = bd.Technology
	AND cj.Architecture = bd.Architecture
	AND cj.Series = bd.Series
	AND cj.Channel = bd.Channel
	AND cj.Inventory_Area = bd.Inventory_Area
	AND cj.Metrics = bd.Metrics
	AND cj.Units = bd.Units

LEFT JOIN #b_data bd_one ON cj.Fiscal_Month_YYYYMM = bd_one.Prior_Month
	AND cj.Business_Unit = bd_one.Business_Unit
	AND cj.DID = bd_one.DID 
	AND cj.Technology = bd_one.Technology
	AND cj.Architecture = bd_one.Architecture
	AND cj.Series = bd_one.Series
	AND cj.Channel = bd_one.Channel
	AND cj.Inventory_Area = bd_one.Inventory_Area
	AND cj.Metrics = bd_one.Metrics
	AND cj.Units = bd_one.Units

LEFT JOIN #b_data bd_two on cj.Fiscal_Month_YYYYMM = bd_two.Two_Prior__Month
	AND cj.Business_Unit = bd_two.Business_Unit
	AND cj.DID = bd_two.DID 
	AND cj.Technology = bd_two.Technology
	AND cj.Architecture = bd_two.Architecture
	AND cj.Series = bd_two.Series
	AND cj.Channel = bd_two.Channel
	AND cj.Inventory_Area = bd_two.Inventory_Area
	AND cj.Metrics = bd_two.Metrics
	AND cj.Units = bd_two.Units

LEFT JOIN #b_data bd_three on cj.Fiscal_Month_YYYYMM = bd_three.Prior_Qtr
	AND cj.Business_Unit = bd_three.Business_Unit
	AND cj.DID = bd_three.DID 
	AND cj.Technology = bd_three.Technology
	AND cj.Architecture = bd_three.Architecture
	AND cj.Series = bd_three.Series
	AND cj.Channel = bd_three.Channel
	AND cj.Inventory_Area = bd_three.Inventory_Area
	AND cj.Metrics = bd_three.Metrics
	AND cj.Units = bd_three.Units

LEFT JOIN v_D_Month dm on cj.Fiscal_Month_YYYYMM = dm.Fiscal_Month_YYYYMM

ORDER BY  cj.Fiscal_Month_YYYYMM

Drop Table #cross_join 
Drop Table #b_data
