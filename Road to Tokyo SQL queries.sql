create database Olympics_Data

use Olympics_Data

if exists(select * from tbl_Olympics)
drop table tbl_Olympics

-----------------------------------------------------------------------------------------

--Creating table to store our data.

create table tbl_Olympics_Summer
(ID int  null, Name varchar(200)  null, Sex varchar(50)  null, 
Age varchar(75)  null, Height varchar(20)  null, Weight varchar(20) null, 
Team varchar(75)  null, NOC varchar(50), Games varchar(60) null,Year varchar(60) null,
Season varchar(60) null, Host_City varchar(75)  null, 
Sport varchar(200)  null, Event_Name varchar(500)  null, 
Medal varchar(100)  null, Misc_1 varchar(500),Misc_2 varchar(500),Misc_3 varchar(500),Misc_4 varchar(500))

-----------------------------------------------------------------------------------------

--Loading data using bulk insert.

bulk insert tbl_Olympics_Summer
from 'C:\Users\user\Downloads\athlete_events.csv'
with(
datafiletype='char',
firstrow=2,
rowterminator='0x0a',
fieldterminator=',',
errorfile='C:\Users\user\Downloads\Temp.Error_txt.txt'
 )
 
-----------------------------------------------------------------------------------------

--Creating a after trigger for looking at the updates.

create trigger TR_Olympics_Summer
on [dbo].[tbl_Olympics]
for delete, insert, update
as
begin
select * from inserted
select * from deleted
set nocount on
end

-----------------------------------------------------------------------------------------

--Creating clustered index for faster query results.

create clustered index IX_ID_Year_tbl_Olympics on tbl_Olympics_Summer(ID,Year)

-----------------------------------------------------------------------------------------

--Cleaning the data using replace, trim and len functions.

update tbl_Olympics_Summer
set Name=replace(replace(replace(replace
		 (replace(Name,')',''),'(-',''),'(',''),'(-',''),'-','')

update tbl_Olympics_Summer
set Name=left(name,len(Name)-1)
where Name like '%-'

update tbl_Olympics_Summer
set Name=trim(Name)

update tbl_Olympics_Summer
set Name=name+' '+Sex
output inserted.*,deleted.*
where Sex<>'M' and Sex<>'F' and Sex<>'NA' 

-----------------------------------------------------------------------------------------

--Getting the data for the count of medals won by countries since 1980.

select distinct count(Medal) over(partition by Team,Year)as MedalsWon, Team, 
datepart(year,convert(date,Year))as Year 
from tbl_Olympics_Summer
where Year >= 1980 and Medal = 'Gold' 
or Year >= 1980 
and Medal = 'Silver' 
or Year >= 1980 and 
Medal = 'Bronze'
order by Year, Team

-----------------------------------------------------------------------------------------

--Getting the total and individual medals(gold, silver, bronze) won by the top 1000 Olympians.

with top_olympians as(select Name, Age,count(Name)over(partition by Name order by Name)as Total_Medals_Won, 
Height, Weight, Medal,Games,Host_City,Sport,Team 
from tbl_Olympics_Summer
where Medal = 'Gold' or Medal = 'Silver' or Medal = 'Bronze'),
Row_Number_ as (select dense_rank()over(order by Total_Medals_Won desc,Name)as row_No, Name, 
Height, Weight,Total_Medals_Won, Medal, Sport, Team 
from top_olympians),
Gold_Medals_Won_Cte as(select Name, Total_Medals_Won, Height, row_No, Weight,
Medal,Sport, count(Medal)over(partition by Name,Medal) as Gold_Medals_Won, Team 
from Row_Number_
where row_No between 1 and 1000 and Medal='Gold')

select distinct Name, Total_Medals_Won, Height, row_No, Weight,
Medal, Sport,Team, concat(Gold_Medals_Won,' ','Gold')as Gold_Medals_Won 
from Gold_Medals_Won_Cte
order by Total_Medals_Won desc;

select distinct Name, Total_Medals_Won, Height, row_No, Weight,
Medal, Sport, concat(Silver_Medals_Won,' ','Silver')as Silver_Medals_Won 
from Silver_Medals_Won
order by Total_Medals_Won desc;

select distinct Name, Total_Medals_Won, Height, row_No, Weight,
Medal, Sport, concat(Bronze_Medals_Won,' ','Bronze')as Bronze_Medals_Won 
from Bronze_Medals_Won
order by Total_Medals_Won desc;

-----------------------------------------------------------------------------------------

--Getting the average weight and height of each event ever in the Summer Olympics.

with AverageWeightAndHeight(Avg_Height,Avg_Weight,Event_Name,Sport) as
(select distinct avg(convert(tinyint,Height))over(partition by Event_Name) as Avg_Height,
avg(convert(decimal(5,2),Weight))
over(partition by Event_Name) as Avg_Weight
,Event_Name,Sport 
from tbl_Olympics_Summer
where Height is not null and Weight is not null)

select Avg_Height,round(Avg_Weight,1) as Avg_Weight,Event_Name,Sport 
from AverageWeightAndHeight

-----------------------------------------------------------------------------------------

--Looking at the participation of men and women since the inception of the Olympics

select distinct count(Name)as count_participants_by_sex, Year, Sex, Host_City 
from tbl_Olympics_Summer
group by Sex, Year, Host_City

-----------------------------------------------------------------------------------------

--Querying the past host cities of the Summer Olympics

select Host_City,Year 
from tbl_Olympics_Summer
group by Year,Host_City
order by Year

-----------------------------------------------------------------------------------------

--Data on the medals won and the number of participants by each country since the 1950 Olympics

with no as(select distinct U.Team,count(U.name)
over(partition by U.Team)as country_participation, Medals_Won 
from tbl_Olympics_Summer as U
left join (select distinct count(Name)over(partition by Team)as Medals_Won, Team 
from tbl_Olympics_Summer 
where Year >= 1950 and Medal = 'Gold' or Year>=1950 and Medal = 'Silver' or Year >= 1950 and Medal = 'Bronze') as T
on U.Team = T.Team
where Year >= 1952)
select distinct * from no 
where country_participation>6 
order by Medals_Won

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------