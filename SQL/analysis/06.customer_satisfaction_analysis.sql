with ranked_reviews as (
SELECT 
        order_id,
        review_score,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp desc) AS rn
    FROM order_reviews)
select review_score,
	count(*) as total_orders,
	round(100.0*count(*)/sum(count(*)) over(),2) as perc_of_total
	from ranked_reviews
	where rn=1
	group by review_score
	order by review_score;
