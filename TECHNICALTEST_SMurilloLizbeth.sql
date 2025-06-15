Create database TETDB

--Creation of tables
create table Users(user_id int primary key, 
username varchar(100),
email varchar(100), 
signup_date date);

create table Subscriptions(subscription_id int primary key, 
user_id int,
plan_type varchar(10) not null, 
start_date date not null,
end_date date null, 
foreign key (user_id) references Users(user_id));

create table Artists(artist_id int primary key,
artist_name varchar(30), 
genre varchar(30), 
country_of_origin varchar(30));--Varchar allows to modify the lenght of the name of the variables

create table Streams(streams_id int primary key, 
user_id int, 
artist_id int, 
stream_date date,
stream_duration_seconds int, --This variable is naturally of type int
foreign key (user_id) references Users(user_id),
foreign key (artist_id) references Artists(artist_id));

--This is for verification
select*from Users
select*from Artists
select*from Streams
select*from Subscriptions

/* Question 1
Management wants to see, for each subscription plan and each artist,
how many distinct users have streamed that artist withing the last 90 days, 
as well as the average stream duration
during that time
*/

select Subscriptions.plan_type, Artists.artist_name,
count(distinct Streams.user_id) as unique_user_count,
avg(Streams.stream_duration_seconds) as avg_stream_duration
from Streams
join Subscriptions on Streams.user_id=Subscriptions.user_id
join Artists on Streams.artist_id=Artists.artist_id
where Streams.stream_date >= dateadd(day, -90,getdate())
group by Subscriptions.plan_type, Artists.artist_name;

/* Question 2
Finance has requested a report that shows each user’s average monthly payment 
across all of their subscriptions and, 
for each of their streams, how that payment is divided 
among the record labels associated with the artist.
*/
--Creation of new tables
create table Record_labels(
label_id int primary key, 
label_name varchar (50) not null); --Stores each record label with its own unique Id and name

create table Artist_labels(
artist_id int, 
label_id int,
foreign key (artist_id) references Artists(artist_id),
foreign key (label_id) references Record_labels(label_id));
select*from Artist_labels --Acts to link artists to record label

--Monthly payment based on their subscription
select user_id, 
avg(
case plan_type
when 'Free' then 0.00
when 'Premium' then 6.99
when 'Family' then 9.99 --I chose these prices based on Spotify's plans
end) as average_monthly_cost
into average_monthly_cost --This acts as a temporal table
from Subscriptions 
group by user_id;

-- Labels associated with the artist
select distinct artist_id,
count(*) as label_count
into artist_label_counts
from Artist_labels
group by artist_id;
select*from artist_label_counts
--
select Streams.user_id,
average_monthly_cost,
Streams.streams_id,
average_monthly_cost
/artist_label_counts.label_count
as label_share_amounts
from Streams
join average_monthly_cost
on Streams.user_id=average_monthly_cost.user_id
join artist_label_counts
on streams.artist_id=artist_label_counts.artist_id

/* Question 3
We store hundreds of millions of rows in the Streams table. 
We’d like a result set for each artist on each day in the last 12 months
*/
 
/*I'm going to separate the tables and convert the 
data from seconds to hours, then to days, and then to months 
(assuming 30 days per month), to keep things organized. 
Since I'm assuming the dataset contains hundreds of millions of records,
the code needs to be executed in parts due to the computer's processing limits.*/

--Total duration in seconds
select artist_id, stream_date,
sum(Streams.stream_duration_seconds) as total_durations
into total_durations
from Streams
group by artist_id, stream_date;
--Converting seconds to hours
select artist_id, stream_date, total_durations,
total_durations/3600 as total_hours --One hour equals 3.600 seconds
into total_hours
from total_durations;
--Converting hours to days
select artist_id, stream_date, total_hours,
total_hours/24 as total_days
into total_days
from total_hours;
--Days to months
select artist_id, stream_date, total_days,
total_days/30 as total_months
into total_months
from total_days;

--Adding months and days in the table
alter table Streams
add total_months int

alter table Streams
add total_days int
select*from Streams 
/*I think using an int is better than a date,
because a date requires a full value
(day, month, year), whereas an int doesn't. */
--
select Streams.stream_date as the_date, 
Streams.artist_id,
count(distinct Streams.user_id) as unique_user_count, 
Streams.total_months as last_12months, 
Streams.total_days as thirty_day_window
from Streams
join Subscriptions 
on Streams.user_id=Subscriptions.user_id
where Streams.total_months >= -12 
and Streams.total_days >= -30 
group by Streams.artist_id, Streams.stream_date, 
Streams.total_months, Streams.total_days;
