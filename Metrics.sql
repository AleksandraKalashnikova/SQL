1. Для каждого дня, представленного в таблицах user_actions и courier_actions, рассчитайте следующие показатели:

Число новых пользователей.
Число новых курьеров.
Общее число пользователей на текущий день.
Общее число курьеров на текущий день.
Прирост числа новых пользователей.
Прирост числа новых курьеров.
Прирост общего числа пользователей.
Прирост общего числа курьеров.
Число платящих пользователей.
Число активных курьеров.
Долю платящих пользователей в общем числе пользователей на текущий день.
Долю активных курьеров в общем числе курьеров на текущий день.

WITH new_users_by_day AS -- определяем количество новых пользователей по дням
                         (SELECT date,
                                 count(distinct user_id) as new_users,
                                 coalesce(sum(count(distinct user_id)) OVER(ORDER BY date), 0) as total_users
                          FROM   (SELECT user_id,
                                         min(time :: date) as "date" 
                                  FROM   user_actions
                                  GROUP BY user_id) as query_in -- определяем дату первого действия в нашем сервисе у пользователя
                          GROUP BY date), 
     new_couriers_by_day AS -- определяем количество новых курьеров по дням
                         (SELECT date,
                                  count(distinct courier_id) as new_couriers,
                                  coalesce(sum(count(distinct courier_id)) OVER(ORDER BY date), 0) as total_couriers
                          FROM   (SELECT courier_id,
                                          min(time :: date) as "date" 
                                  FROM   courier_actions
                                  GROUP BY courier_id) as query_in -- определяем дату первого действия в нашем сервисе у курьера
                          GROUP BY date),
    paying_users_by_day AS -- определяем количество платящих пользователей по дням
                          (SELECT date(time) AS date,
                                  COUNT(DISTINCT user_id) AS paying_users
                           FROM user_actions       
                           WHERE order_id not in (
                                    SELECT order_id FROM user_actions
                                    WHERE action = 'cancel_order') -- Исключаем отмененные заказы
                           GROUP BY date(time)),
    active_couriers_by_day AS -- определяем количество активных курьеров по дням
                          (SELECT date(time) AS date,
                                  COUNT(DISTINCT courier_id) AS active_couriers
                           FROM courier_actions
                           WHERE order_id not in (
                                    SELECT order_id FROM user_actions
                                    WHERE action = 'cancel_order') -- Исключаем отмененные заказы
                           GROUP BY date(time))
SELECT date,
       new_users, -- число новых пользователей
       new_couriers, -- число новых курьеров
       cast(total_users as integer), -- общее число пользователей на текущий день
       cast(total_couriers as integer), -- общее число курьеров на текущий день
       ROUND((new_users - LAG(new_users) OVER(ORDER BY date)) * 100.00 / LAG(new_users) OVER(ORDER BY date), 2) AS new_users_change, -- прирост числа новых пользователей
       ROUND((new_couriers - LAG(new_couriers) OVER(ORDER BY date)) * 100.00 / LAG(new_couriers) OVER(ORDER BY date), 2) AS new_couriers_change, -- прирост числа новых курьеров
       ROUND(new_users * 100.00 / LAG(total_users) OVER(ORDER BY date), 2) AS total_users_growth, -- прирост общего числа пользователей
       ROUND(new_couriers * 100.00 / LAG(total_couriers) OVER(ORDER BY date), 2) AS total_couriers_growth, -- прирост общего числа курьеров
       paying_users, -- число платящих пользователей
       active_couriers, -- число активных курьеров
       ROUND(paying_users * 100.00 / total_users, 2) AS paying_users_share, -- доля платящих пользователей в общем числе пользователей на текущий день
       ROUND(active_couriers * 100.00 / total_couriers, 2) AS active_couriers_share -- доля активных курьеров в общем числе курьеров на текущий день
FROM   new_users_by_day 
  JOIN new_couriers_by_day using(date)
  JOIN paying_users_by_day USING(date)
  JOIN active_couriers_by_day USING(date)

2. Для каждого дня в таблице orders рассчитайте следующие показатели:

Выручку, полученную в этот день.
Суммарную выручку на текущий день.
Прирост выручки, полученной в этот день, относительно значения выручки за предыдущий день.

SELECT
  date,
  revenue,
  SUM(revenue) OVER(ORDER BY date) AS total_revenue,
  ROUND((revenue - LAG(revenue) OVER(ORDER BY date)) * 100 / LAG(revenue) OVER(ORDER BY date), 2) AS revenue_change
FROM
  (SELECT
    DISTINCT(DATE(creation_time)) AS date,
    SUM(price) AS revenue
  FROM
      (SELECT
        creation_time,
        unnest(product_ids) as product_id --разворачиваем массив идентификаторов продуктов в строки
      FROM
        orders
      WHERE
        order_id not in (
            SELECT order_id FROM user_actions
            WHERE action = 'cancel_order' -- исключаем отмененные заказы
          )) AS query_in
      LEFT JOIN products USING(product_id)
    GROUP BY 1
  ) AS revenue_by_day