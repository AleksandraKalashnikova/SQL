1. Для каждого дня, представленного в таблицах user_actions и courier_actions, рассчитайте следующие показатели:

Число новых пользователей.
Число новых курьеров.
Общее число пользователей на текущий день.
Общее число курьеров на текущий день.
Прирост числа новых пользователей.
Прирост числа новых курьеров.
Прирост общего числа пользователей.
Прирост общего числа курьеров.

WITH new_users_by_day AS (SELECT date,
                                 count(distinct user_id) as new_users,
                                 coalesce(sum(count(distinct user_id)) OVER(ORDER BY date), 0) as total_users
                          FROM   (SELECT user_id,
                                         min(time :: date) as "date"
                                  FROM   user_actions
                                  GROUP BY user_id) as query_in
                          GROUP BY date), new_couriers_by_day as (SELECT date,
                                               count(distinct courier_id) as new_couriers,
                                               coalesce(sum(count(distinct courier_id)) OVER(ORDER BY date), 0) as total_couriers
                                        FROM   (SELECT courier_id,
                                                       min(time :: date) as "date"
                                                FROM   courier_actions
                                                GROUP BY courier_id) as query_in
                                        GROUP BY date)
SELECT date,
       new_users,
       new_couriers,
       cast(total_users as integer),
       cast(total_couriers as integer),
       ROUND((new_users - LAG(new_users) OVER(ORDER BY date)) * 100.00 / LAG(new_users) OVER(ORDER BY date), 2) AS new_users_change,
       ROUND((new_couriers - LAG(new_couriers) OVER(ORDER BY date)) * 100.00 / LAG(new_couriers) OVER(ORDER BY date), 2) AS new_couriers_change,
       ROUND(new_users * 100.00 / LAG(total_users) OVER(ORDER BY date), 2) AS total_users_growth,
       ROUND(new_couriers * 100.00 / LAG(total_couriers) OVER(ORDER BY date), 2) AS total_couriers_growth
FROM   new_users_by_day JOIN new_couriers_by_day using(date)
