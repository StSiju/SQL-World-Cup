--1.	How many Wolrd cup games have been held?

Select distinct count(year)number_of_games
From WorldCups

Select count(distinct year)number_of_games
From WorldCupMatches


--2.	List all Wolrd cup games held so far

Select concat ( year, '-', Country) Tournaments_host
From WorldCups



--3.  How many countries have participated in World cup since its Inception

SELECT count(distinct sub.Team1) NumberOfCountries
FROM
    (SELECT [Home Team Name] Team1
     FROM WorldCupMatches
     UNION ALL
     SELECT [Away Team Name]
     FROM WorldCupMatches) sub


--4.	How many countries participated in each Wolrd cup ?

SELECT year, count(distinct sub.Team1) NumberOfCountries
FROM
    (SELECT Year, [Home Team Name] Team1
     FROM WorldCupMatches
     UNION ALL
     SELECT year, [Away Team Name]
     FROM WorldCupMatches) sub
GROUP BY year
ORDER BY year;


--5.	Number of Goal Per Country

SELECT sub.Team1, Sum(sub.Goal1) AS SumOfgoals
FROM
    (SELECT Year, [Home Team Name] Team1, [Home Team Goals] Goal1
     FROM WorldCupMatches
     UNION ALL
     SELECT year, [Away Team Name], [Away Team Goals] 
     FROM WorldCupMatches) sub
GROUP BY sub.Team1
ORDER BY SumOfgoals desc;


--6.	How many goals were scored by each teams in each tournament

SELECT year, sub.Team1, Sum(sub.Goal1) AS SumOfgoals
FROM
    (SELECT Year, [Home Team Name] Team1, [Home Team Goals] Goal1
     FROM WorldCupMatches
     UNION ALL
     SELECT year, [Away Team Name], [Away Team Goals] 
     FROM WorldCupMatches) sub
GROUP BY year, sub.Team1
ORDER BY year


--7.	Match with the highest attendance in each tournament

Select Year, Datetime, Stage, Stadium, City ,concat([Home Team Name], ' vs ', [Away Team Name]) Matchh, Attendance
From(
	Select Year, Datetime, Stage, Stadium, City, [Home Team Name], [Away Team Name], Attendance ,DENSE_RANK()over (partition by year order by attendance desc)rnk
	From WorldCupMatches)sub
where rnk=1


Select distinct Year, FIRST_VALUE(attendance) over (partition by year order by attendance desc) MaxAttenPerYear
From WorldCupMatches


Select distinct FIRST_VALUE(Year) over (partition by year order by attendance desc) Year,
				FIRST_VALUE(Datetime) over (partition by year order by attendance desc) Datetime,
				FIRST_VALUE(Stage) over (partition by year order by attendance desc) Stage,
				FIRST_VALUE(Stadium) over (partition by year order by attendance desc) Stadium,
				FIRST_VALUE(City) over (partition by year order by attendance desc) City,
				concat(FIRST_VALUE([Home Team Name]) over (partition by year order by attendance desc), 
				' VS ', FIRST_VALUE([Away Team Name]) over (partition by year order by attendance desc)) MatchPlayed,
				FIRST_VALUE(attendance) over (partition by year order by attendance desc) MaxAttenPerYear
From WorldCupMatches

--NOTE: Window functions always return all rows in each partition after solving for the window command


--8.	Stadium with Highest Average Attendance

with Temp as
	(Select *, DENSE_RANK()over(order by avg_att desc) rnk
	 From(
		Select Stadium, City, cast(AVG(Attendance)as decimal (10,2)) as avg_att
		From WorldCupMatches
		Group by Stadium, City)sub)
Select *
From Temp
where rnk=1


--9.	Show the years that had the highest and lowest no of countries participating in the tournament

with temp1 as
	(SELECT year, count(distinct sub.Team1) NumberOfCountries
	FROM
		(SELECT Year, [Home Team Name] Team1
		 FROM WorldCupMatches
		 UNION ALL
		 SELECT year, [Away Team Name]
		 FROM WorldCupMatches) sub
	GROUP BY year)
select distinct
	concat(first_value(year) over(order by NumberOfCountries),' - ', first_value(NumberOfCountries) over(order by NumberOfCountries)) as Lowest_Participating_Countries,
	concat(first_value(year) over(order by NumberOfCountries desc), ' - ', first_value(NumberOfCountries) over(order by NumberOfCountries desc)) as Highest_Participating_Countries
	from temp1;



with temp1 as
	(SELECT year, country, count(distinct sub.Team1) NumberOfCountries
	FROM
		(SELECT M1.Year, country, [Home Team Name] Team1
		 FROM WorldCupMatches M1
		 join WorldCups W1 on M1.year=W1.year
		 UNION ALL
		 SELECT M2.year, country, [Away Team Name]
		 FROM WorldCupMatches M2
		 join WorldCups W2 on M2.year=W2.year) sub
	GROUP BY year, Country)
select distinct
	concat(first_value(year) over(order by NumberOfCountries), ' - ', first_value(country) over(order by NumberOfCountries),
	' - ', first_value(NumberOfCountries) over(order by NumberOfCountries)) as Lowest_Participating_Countries,
	concat(first_value(year) over(order by NumberOfCountries desc), ' - ', first_value(country) over(order by NumberOfCountries desc), 
	' - ', first_value(NumberOfCountries) over(order by NumberOfCountries desc)) as Highest_Participating_Countries
	from temp1




--10.	Which nation(s) has participated in all of the World cup Tournaments

with T1 as 
	(Select count(distinct year) TotalTournament
	From WorldCupMatches),
	T2 as
	(Select Team1, count(distinct year) CountTournament
	From(
		SELECT Year, [Home Team Name] Team1
		FROM WorldCupMatches
		UNION ALL
		SELECT year, [Away Team Name]
		FROM WorldCupMatches)sub
	Group by Team1)
Select T2.*
From T1 Join T2
on T1.TotalTournament= T2.CountTournament


--11.	Which country has won the tournament the most

Select *
From(
	Select winner, CountWin, DENSE_RANK()over(order by CountWin desc) rnk
	From(
		Select Winner, count(year) CountWin
		From WorldCups
		Group by winner)sub)sub2
where rnk=1


--12.	What is the ratio of the tournaments with the lowest and highest attendances

with Highest as
	(Select distinct FIRST_VALUE(attendance)over(order by attendance desc) H_attendance
	From WorldCups),
Lowest as
	(Select distinct FIRST_VALUE(attendance)over(order by attendance) L_attendance
	From WorldCups)
Select concat('1:', round(cast((H_attendance) as float)/cast((L_attendance) as float),2)) ratio
From Highest, lowest




with Highest as
	(Select distinct FIRST_VALUE(attendance)over(order by attendance desc) H_attendance
	From WorldCups),
Lowest as
	(Select distinct FIRST_VALUE(attendance)over(order by attendance) L_attendance
	From WorldCups)
Select concat('1:', round(H_attendance/cast(L_attendance as decimal(20,2)),2)) ratio
From Highest, lowest



--13.	Fetch the top 5 players who have participated in most tournaments

with T1 as
	(Select *, DENSE_RANK()over(order by Tournament_count desc)rnk
	From(
		Select distinct [Player Name], count(distinct year) Tournament_count
		From WorldCupMatches WM
		join Players WP
		on WM.MatchID=WP.MatchID
		group by [Player Name])sub)
Select *
From T1
where rnk<6

-------------------------------------

--with T1 as
--	(Select *, DENSE_RANK()over(order by Tournament_count desc)rnk
--	From(
--		Select case when [Player Name]= 'Ronaldo' and [Team Initials]= 'Bra' Then 'Ronaldo De lima'
--		when [Player Name] in ('Ronaldo', 'C.Ronaldo') and [Team Initials]= 'por' then 'C.Ronaldo' 
--		else [Player Name] end as Player_Name, count(distinct year) Tournament_count
--		From WorldCupMatches WM
--		join WorldCupPlayers WP
--		on WM.MatchID=WP.MatchID
--		group by [Player Name], [Team Initials])sub)
--Select *
--From T1
--where Player_Name like '%ronaldo%'
--group by Player_Name, Tournament_count, rnk;

---------------------------------------

--with T1 as
--	(Select *, DENSE_RANK()over(order by Tournament_count desc)rnk
--	From(
--		Select case when [Player Name]= 'Ronaldo' and [Team Initials]= 'Bra' Then 'Ronaldo De lima'
--		when trim([Player Name]) in ('Ronaldo', 'C.Ronaldo') and [Team Initials]= 'por' then 'C.Ronaldo' 
--		else [Player Name] end as Player_Name, count(distinct year) Tournament_count
--		From WorldCupMatches WM
--		join WorldCupPlayers WP
--		on WM.MatchID=WP.MatchID
--		group by [Player Name], [Team Initials])sub)
--Select *
--From T1
--where Player_Name like '%ronaldo%'
--group by Player_Name, Tournament_count, rnk;



--14.	Which player has won the tournament the most

--Select distinct [Player Name], count(distinct winner)TournamentWon
--From Players P 
--join WorldCupMatches WM
--on P.MatchID=WM.MatchID
--join WorldCups WC
--on WC.Year=WM.Year
--group by [Player Name]
--order by TournamentWon desc

--14.	List the number of Quater finals, Semi Finals, Third place and Finals that each country has played in.


Select  Team1,
		sum(case when Stage='Quarter-finals' then 1 else 0 end) as QuarterFinals,
		sum(case when Stage='Semi-finals' then 1 else 0 end) as SemiFinals,
		sum(case when Stage='Match for third place' then 1 else 0 end) as ThirdPlace,
		sum(case when Stage='Final' then 1 else 0 end) as Finals
From(
	SELECT distinct year, Stage, [Home Team Name] Team1
	FROM WorldCupMatches
	UNION ALL
	SELECT distinct year, Stage, [Away Team Name]
	FROM WorldCupMatches)sub
Group by Team1



--15.	Identify which countries have played in most Quater finals, Semi Finals and Finals

with T1 as
	(Select Team1,
			sum(case when Stage='Quarter-finals' then 1 else 0 end) as QuarterFinals,
			sum(case when Stage='Semi-finals' then 1 else 0 end) as SemiFinals,
			sum(case when Stage='Match for third place' then 1 else 0 end) as ThirdPlace,
			sum(case when Stage='Final' then 1 else 0 end) as Finals
	From(
		SELECT distinct year, Stage, [Home Team Name] Team1
		FROM WorldCupMatches
		UNION ALL
		SELECT distinct year, Stage, [Away Team Name]
		FROM WorldCupMatches)sub
	Group by Team1)

SELECT  distinct concat(first_value(Team1) over( order by Quarterfinals desc) , ' - ', first_value(Quarterfinals) over(order by Quarterfinals desc)) as Max_Quarterfinals,
    	concat(first_value(Team1) over(order by SemiFinals desc), ' - ', first_value(SemiFinals) over(order by SemiFinals desc)) as Max_SemiFinals,
    	concat(first_value(Team1) over(order by ThirdPlace desc), ' - ', first_value(ThirdPlace) over(order by ThirdPlace desc)) as Max_ThirdPlace,
		concat(first_value(Team1) over(order by Finals desc), ' - ', first_value(Finals) over(order by Finals desc)) as Max_Finals
From T1



--16.	Which countries have never played in the round of 16?

Select *
From(
	Select  Team1,
			sum(case when Stage='Round of 16' then 1 else 0 end) as QuarterFinals
	From(
		SELECT distinct year, Stage, [Home Team Name] Team1
		FROM WorldCupMatches
		UNION ALL
		SELECT distinct year, Stage, [Away Team Name]
		FROM WorldCupMatches)sub
	Group by Team1)sub
where QuarterFinals=0




----------------------------------------------------------------------
----------------------------------------------------------------------

---------------------------------------------------------------------
---To get the teams and goals scored in just two columns, rather than 4 columns

Select year, Team, sum(goal) cnt
From(
	SELECT Year, [Home Team Name] Team, [Home Team Goals] Goal
	FROM WorldCupMatches
	UNION ALL
	SELECT year, [Away Team Name], [Away Team Goals]
	FROM WorldCupMatches)sub
Group by year, team
order by year



Select year, Team, sum(goal) cnt
From(
	SELECT Year,[Datetime],[Stage], [Stadium],[City],[Home Team Name] Team, [Home Team Goals] Goal, [Win conditions],
	[Attendance],[Half-time Home Goals],[Half-time Away Goals],[Referee],[Assistant 1],[Assistant 2],[RoundID] ,[MatchID] ,[Home Team Initials],[Away Team Initials]
	FROM WorldCupMatches
	UNION ALL
	SELECT year, [Datetime],[Stage], [Stadium],[City],[Away Team Name], [Away Team Goals],[Win conditions],
	[Attendance],[Half-time Home Goals],[Half-time Away Goals],[Referee],[Assistant 1],[Assistant 2],[RoundID] ,[MatchID] ,[Home Team Initials] ,[Away Team Initials]
	FROM WorldCupMatches)sub --- display all columns except the initially merged 4 columns
Group by year, team
order by year



Select year, Team, sum(goal) cnt
From(
	SELECT Year,[Datetime],[Stage], [Stadium],[City],[Home Team Name] Team, [Home Team Goals] Goal, [Win conditions],
	[Attendance],[Half-time Home Goals],[Half-time Away Goals],[Referee],[Assistant 1],[Assistant 2],[RoundID] ,[MatchID] ,[Home Team Initials],[Away Team Initials]
	FROM WorldCupMatches
	UNION ALL
	SELECT year, [Datetime],[Stage], [Stadium],[City],[Away Team Name], [Away Team Goals],[Win conditions],
	[Attendance],[Half-time Home Goals],[Half-time Away Goals],[Referee],[Assistant 1],[Assistant 2],[RoundID] ,[MatchID] ,[Home Team Initials] ,[Away Team Initials]
	FROM WorldCupMatches)sub --- display all columns except the initially merged 4 columns
Group by year, team
order by year