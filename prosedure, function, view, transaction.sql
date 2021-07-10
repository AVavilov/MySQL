use online_school;

-- PROCEDURE

-- Новые покупки пользователей
drop procedure if exists cp_new_order;
delimiter \\
\\
create procedure cp_new_order (c_id int, u_id int, out  tran_result varchar(100))
begin
	
	declare _rollback bool default false;
	declare continue handler for sqlexception
		begin
	 		set _rollback = true;
		end;

	start transaction;
		insert into orders (course_id, user_id, cost, create_dt)
		select c_id, u_id, cost, now()
		from courses where id = c_id;
		
		insert into order_users (user_id, order_id)
		values (u_id, last_insert_id());
			
	if _rollback then
		set tran_result = 'ROLLBACK';
		rollback;
	else
		set tran_result = 'COMMIT';
		commit;
	end if;
end\\
delimiter ;


-- Запуск процедуры
call cp_new_order (1, 95, @tran_result);
select @tran_result;


-- Проверка таблиц
select * from order_users;
select * from orders;




-- Все покупки курсов за последние 30 дней
drop procedure if exists all_shop;
delimiter \\
\\
create procedure all_shop (out  tran_result varchar(100))
begin
	
	declare _rollback bool default false;
	declare continue handler for sqlexception
		begin
	 		set _rollback = true;
		end;

	select 
		concat(u.firstname, ' ', u.lastname) as fio,
		c.name_course,
		c.cost
	from users as u 
	left join orders as o on o.user_id = u.id 
	join courses as c on c.id = o.course_id
	where status = 'student'
		and o.create_dt >= now() - interval 30 day
	order by c.cost desc;
			
	if _rollback then
		set tran_result = 'Что то пошло не так';
		rollback;
	else
		set tran_result = 'Успех';
		commit;
	end if;
end\\
delimiter ;

-- Запуск процедуры
call all_shop(@tran_result);



-- FUNCTION


-- Минимальная стоимость курса
drop function course_order_cash;
delimiter \\
\\
create function course_order_cash (course_id_f int)
returns float reads sql data
begin 
	declare course_cash int;

	select min(cost) into course_cash from orders where course_id = course_id_f;
	return course_cash;
end\\
delimiter ;


-- Запуск функции
select * from orders where cost > course_order_cash(5);




-- Доля преподователя с одного курса
drop function salary_teacher;
delimiter \\
\\
create function salary_teacher ()
returns float reads sql data
begin 
	declare percent_course float;

	set percent_course = 10 / 100;
	return percent_course;
end\\
delimiter ;


-- Запуск функции
select 
	gc.teacher_id, 
	gc.course_id, 
	round(sum(c.cost) * salary_teacher(), 0) as salary_teacher
from groups_course as gc
join courses as c on c.id = gc.course_id  
group by gc.teacher_id
order by salary_teacher desc



-- VIEW


-- Актиновсти пользователей. Лайки комментарии.
drop view if exists v_avtive_users;
create view v_avtive_users as 
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
group by c.id;


-- Запуск представления
select * from v_avtive_users;



-- ТОП 3 "М" и "Ж" по кол-ву набранным баллам в тестах.
drop view if exists v_sex_test;
create view v_sex_test as 
(select t.student_id, u.sex, round(sum(points) / count(*), 1) as avg_bal
from tests as t
join users as u on u.id = t.student_id and u.sex = 'm'
group by student_id
order by avg_bal desc limit 3)

union

(select t.student_id, u.sex, round(sum(points) / count(*), 1) as avg_bal
from tests as t
join users as u on u.id = t.student_id and u.sex = 'w'
group by student_id
order by avg_bal desc limit 3);


-- Запуск представления
select * from v_sex_test;


-- TRIGGER


-- После покупки, меняем статус user на student
drop trigger if exists new_student;
delimiter \\
create trigger new_student after insert on orders
for each row 
begin 
	update users set status = 'student'
	where id = new.user_id;
end\\
delimiter ;

-- Проверка тригера, необходимо запустить процедуру с id от 90 и выше
call cp_new_order (5, 100, @tran_result);
-- Статус поменяется
select * from users u 





