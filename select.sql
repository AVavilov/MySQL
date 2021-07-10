use online_school;


-- Все покупки курсов

select 
	concat(u.firstname, ' ', u.lastname) as fio,
	c.name_course,
	c.cost
from users as u 
left join orders as o on o.user_id = u.id 
join courses as c on c.id = o.course_id
where status = 'student'
order by c.cost desc;


-- Сумма всех купленных курсов

select 
	concat(firstname, ' ', lastname) as fio,
	sum(cost) as amount
from 
	(
	select 
		u.*,
		c.name_course,
		c.cost
	from users as u 
	left join orders as o on o.user_id = u.id 
	join courses as c on c.id = o.course_id
	where status = 'student'
	) a
where cost is not null
group by id
order by amount desc;


-- Доля приобретенных курсов по студентам

select 
	concat(firstname, ' ', lastname) as fio,
	sum(cnt_les) as cnt_lesson,
	sum(cost) as amount,
	round(sum(cost) * 100 / sum(sum(cost)) over (), 2)  as percent
from 
	(
	select 
		u.id, u.firstname, u.lastname,
		count(*) as cnt_les,
		c.name_course,
		c.cost
	from users as u 
	left join orders as o on o.user_id = u.id 
	join courses as c on c.id = o.course_id
	where status = 'student'
	group by 1,2,3,5,6
	) a
where cost is not null
group by id
order by amount desc, percent;


-- Самый прибыльный курс

select 
	name_course,
	sum(case when c.cost > 0 then 1 else 0 end) as cnt_lesson,
	sum(c.cost) as amount,
	round(sum(c.cost) * 100 / sum(sum(c.cost)) over (), 2) as percent
from courses as c 
left join orders as o on c.id = o.course_id
group by name_course
order by amount desc, percent;


-- Начало обучения. Курсы, учителя, студенты.
	
select 
	gc.teacher_id, 
	concat(u2.firstname, ' ', u2.lastname) as fio_teacher,
	c.name_course,
	gc.start_date,
	date(gc.start_date) + interval (gc.cnt_lesson / 2 * 7) day as end_date, -- Два занятия в неделю
	count(*) as cnt_student, 
	sum(case when u.sex = 'm' then 1 else 0 end) as 'm', -- Кол-во "М", "Ж"
	sum(case when u.sex = 'w' then 1 else 0 end) as 'w'
from users as u
join groups_course as gc on u.id = gc.student_id  
join users as u2 on u2.id = gc.teacher_id 
left join courses as c on c.id = gc.course_id 
group by gc.teacher_id; 


-- Рейтинг по курсам, комментарии и баллы студентов. Через временную таблицу
-- Сначала CREATE с первого раза через DROP выдаст ошибку.

drop temporary table comments_points;
create temporary table comments_points as ( 
select distinct
	c.name_course,
	count(*) as cnt_comment,
	sum(c2.`like`) as cnt_likes,
	t.cnt_tests,
	total_points
from courses as c 
left join comments as c2 on c.id = c2.course_id 
left join 
	(
	select course_id, count(*) as cnt_tests, sum(points) as total_points 
	from tests
	group by course_id
	) t on t.course_id = c.id 
group by c.id);
	
select 
    name_course,
    cnt_comment,
    cnt_likes,
    dense_rank () over (order by cnt_likes) as like_rnk,
    cnt_tests,
    total_points,
    dense_rank () over (order by total_points) as point_rnk	
from comments_points
order by like_rnk, point_rnk

