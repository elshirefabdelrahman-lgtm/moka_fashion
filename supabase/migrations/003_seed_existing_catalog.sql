-- Represents the existing index.html catalog. Local image paths remain valid fallbacks.
insert into public.collections(name, slug, description, image_url, is_active, sort_order) values
  ('Featured Products','featured','MOKA men''s clothing and featured pieces','m1.1.jpeg',true,10),
  ('Wide Leg Pants','pants','Premium wide-leg silhouettes','p1.jpeg',true,20),
  ('Linen Suit Collection','women-linen','Women''s linen suit collection','linen-beige.jpeg',true,30),
  ('Shoes','shoes','MOKA footwear collection','lv1 white .jpeg',true,40)
on conflict (slug) do update set
  name=excluded.name, description=excluded.description, image_url=excluded.image_url,
  is_active=excluded.is_active, sort_order=excluded.sort_order;

with catalog(slug,name,description,price,collection_slug,sizes,colors) as (values
  ('ranger-t-shirt','Ranger T-Shirt','Box Fit T-Shirt (Shoulders)',650,'featured',array['M','L','XL','XXL'],array['White','Black','Gray']),
  ('box-fit-t-shirt','Box Fit T-Shirt','Premium box fit T-shirt',650,'featured',array['M','L','XL','XXL'],array['White','Black','Gray']),
  ('demio-oversize','Demio Oversize','Premium oversized T-shirt',650,'featured',array['M','L','XL','XXL'],array['White','Black','Gray']),
  ('geesas-boxfit','Boxfit (It Will All Be Geesas)','Premium box fit T-shirt',650,'featured',array['M','L','XL','XXL'],array['White','Black','Gray']),
  ('basic-oversize','Basic Oversize','Essential oversized T-shirt',600,'featured',array['M','L','XL','XXL'],array['White','Black','Burgundy']),
  ('wide-leg-pants','Wide Leg Pants','Premium wide-leg silhouette',750,'pants',array['M','L','XL','XXL'],array['Grey','Black']),
  ('beige-linen-suit','Beige Linen Suit','Refined linen tailoring with an effortless silhouette.',850,'women-linen',array['M','L','XL','XXL'],array['Beige']),
  ('black-linen-suit','Black Linen Suit','Refined linen tailoring with an effortless silhouette.',850,'women-linen',array['M','L','XL','XXL'],array['Black']),
  ('black-linen-suit-buttons','Black Linen Suit (Buttons)','Refined linen tailoring with an effortless silhouette.',850,'women-linen',array['M','L','XL','XXL'],array['Black — Button Style']),
  ('brown-linen-suit-buttons','Brown Linen Suit (Buttons)','Refined linen tailoring with an effortless silhouette.',850,'women-linen',array['M','L','XL','XXL'],array['Brown — Button Style']),
  ('dark-blue-linen-suit-buttons','Dark Blue Linen Suit (Buttons)','Refined linen tailoring with an effortless silhouette.',850,'women-linen',array['M','L','XL','XXL'],array['Dark Blue — Button Style']),
  ('light-pink-linen-suit-buttons','Light Pink Linen Suit (Buttons)','Refined linen tailoring with an effortless silhouette.',850,'women-linen',array['M','L','XL','XXL'],array['Light Pink — Button Style']),
  ('yellow-linen-suit','Yellow Linen Suit','Refined linen tailoring with an effortless silhouette.',850,'women-linen',array['M','L','XL','XXL'],array['Yellow']),
  ('lv1-white','LV1 White','Luxury statement sneaker.',1200,'shoes',array['41','42','43','44','45'],array['White']),
  ('lv2-black','LV2 Black','Luxury statement sneaker.',1200,'shoes',array['41','42','43','44','45'],array['Black']),
  ('lv5-black','LV5 Black','Luxury statement sneaker.',1200,'shoes',array['41','42','43','44','45'],array['Black']),
  ('lv7-black','LV7 Black','Luxury statement sneaker.',1200,'shoes',array['41','42','43','44','45'],array['Black']),
  ('lv8-white','LV8 White','Luxury statement sneaker.',1200,'shoes',array['41','42','43','44','45'],array['White']),
  ('nbe1-camel','NBE1 Camel','Premium everyday sneaker.',650,'shoes',array['41','42','43','44','45'],array['Camel']),
  ('nbe2-black','NBE2 Black','Premium everyday sneaker.',650,'shoes',array['41','42','43','44','45'],array['Black']),
  ('nbe3-white','NBE3 White','Premium everyday sneaker.',650,'shoes',array['41','42','43','44','45'],array['White']),
  ('trx1-gray','TRX1 Gray','Luxury streetwear sneaker.',650,'shoes',array['41','42','43','44','45'],array['Gray']),
  ('trx2-white','TRX2 White','Luxury streetwear sneaker.',650,'shoes',array['41','42','43','44','45'],array['White']),
  ('trx3-black','TRX3 Black','Luxury streetwear sneaker.',650,'shoes',array['41','42','43','44','45'],array['Black']),
  ('trx4-gray','TRX4 Gray','Luxury streetwear sneaker.',650,'shoes',array['41','42','43','44','45'],array['Gray']),
  ('trx6-black','TRX6 Black','Luxury streetwear sneaker.',650,'shoes',array['41','42','43','44','45'],array['Black']),
  ('chunky-1','Chunky 1','Sculpted statement sneaker.',950,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('chunky-2','Chunky 2','Sculpted statement sneaker.',950,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('chunky-3','Chunky 3','Sculpted statement sneaker.',950,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('chunky-5','Chunky 5','Sculpted statement sneaker.',950,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('chunky-6','Chunky 6','Sculpted statement sneaker.',950,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('clog-1','Clog 1','Contemporary comfort clog.',750,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('clog-2','Clog 2','Contemporary comfort clog.',750,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('clog-3','Clog 3','Contemporary comfort clog.',750,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('clog-4','Clog 4','Contemporary comfort clog.',750,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('clog-5','Clog 5','Contemporary comfort clog.',750,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('loor-3','Loor 3','Minimal everyday sneaker.',550,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('loor-5','Loor 5','Minimal everyday sneaker.',550,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('loor-7','Loor 7','Minimal everyday sneaker.',550,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('loor-8','Loor 8','Minimal everyday sneaker.',550,'shoes',array['41','42','43','44','45'],array['As shown']),
  ('loor-9','Loor 9','Minimal everyday sneaker.',550,'shoes',array['41','42','43','44','45'],array['As shown'])
)
insert into public.products(slug,name,description,price,collection_id,available_sizes,available_colors,is_active)
select c.slug,c.name,c.description,c.price,col.id,c.sizes,c.colors,true
from catalog c join public.collections col on col.slug=c.collection_slug
on conflict (slug) do update set
  name=excluded.name, description=excluded.description, price=excluded.price,
  collection_id=excluded.collection_id, available_sizes=excluded.available_sizes,
  available_colors=excluded.available_colors;

with image_data(product_slug,image_url,sort_order) as (values
  ('ranger-t-shirt','m1.1.jpeg',1),('ranger-t-shirt','m1.2.jpeg',2),('ranger-t-shirt','1.3.jpeg',3),
  ('box-fit-t-shirt','2.1.jpeg',1),('box-fit-t-shirt','2.2.jpeg',2),('box-fit-t-shirt','2.3.jpeg',3),
  ('demio-oversize','3.1.jpeg',1),('demio-oversize','3.2.jpeg',2),('demio-oversize','3.3.jpeg',3),
  ('geesas-boxfit','4.1.jpeg',1),('geesas-boxfit','4.2.jpeg',2),('geesas-boxfit','4.3.jpeg',3),
  ('basic-oversize','5.1.jpeg',1),('basic-oversize','5.2.jpeg',2),('basic-oversize','5.3.jpeg',3),
  ('wide-leg-pants','p1.jpeg',1),('wide-leg-pants','p2.jpeg',2),
  ('beige-linen-suit','linen-beige.jpeg',1),('black-linen-suit','linen-black .png',1),
  ('black-linen-suit-buttons','linen-black-buttons.jpeg',1),('brown-linen-suit-buttons','linen-brown-buttons.jpeg',1),
  ('dark-blue-linen-suit-buttons','linen-dark-blue-buttons.jpeg',1),('light-pink-linen-suit-buttons','linen-lightpink-buttons.jpeg',1),
  ('yellow-linen-suit','linen-yellow.png',1),
  ('lv1-white','lv1 white .jpeg',1),('lv2-black','lv2 black .jpeg',1),('lv5-black','lv5 black.jpeg',1),
  ('lv7-black','lv7 black.jpeg',1),('lv8-white','lv8 white.jpeg',1),('nbe1-camel','nbe1 camel .jpeg',1),
  ('nbe2-black','nbe2 black .jpeg',1),('nbe3-white','nbe3 white.jpeg',1),('trx1-gray','trx1 gray.jpeg',1),
  ('trx2-white','trx2 white .jpeg',1),('trx3-black','trx3 black.jpeg',1),('trx4-gray','trx4 gray .jpeg',1),
  ('trx6-black','trx6 black.jpeg',1),('chunky-1','chunky1.jpeg',1),('chunky-2','chunky2.jpeg',1),
  ('chunky-3','chunky3.jpeg',1),('chunky-5','chunky5.jpeg',1),('chunky-6','chunky6.jpeg',1),
  ('clog-1','clog1.jpeg',1),('clog-2','clog2.jpeg',1),('clog-3','clog3.jpeg',1),
  ('clog-4','clog4.jpeg',1),('clog-5','colg5.jpeg',1),('loor-3','loor3.jpeg',1),
  ('loor-5','loor5.jpeg',1),('loor-7','loor7.jpeg',1),('loor-8','loor8.jpeg',1),('loor-9','loor9.jpeg',1)
)
insert into public.product_images(product_id,image_url,sort_order,alt_text)
select p.id,i.image_url,i.sort_order,p.name
from image_data i join public.products p on p.slug=i.product_slug
on conflict (product_id,image_url) do update set sort_order=excluded.sort_order, alt_text=excluded.alt_text;

