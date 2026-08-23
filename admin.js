import { getSupabaseClient } from './supabase-client.js';

const state = { sb:null, orders:[], customers:[], products:[], collections:[] };
const money = value => `${Number(value || 0).toLocaleString('en-EG')} EGP`;
const esc = value => String(value ?? '').replace(/[&<>'"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
const date = value => value ? new Date(value).toLocaleString('en-EG') : '';
const modal = document.querySelector('#adminModal');

function notice(message, error=false){ document.querySelector('#notice').innerHTML = `<p class="${error?'error':'success'}">${esc(message)}</p>`; }
function table(headers, rows){ return `<table><thead><tr>${headers.map(h=>`<th>${h}</th>`).join('')}</tr></thead><tbody>${rows || `<tr><td colspan="${headers.length}" class="muted">No data found.</td></tr>`}</tbody></table>`; }
function csv(value){ return Array.isArray(value) ? value.join(', ') : (value || ''); }
function openModal(html){ document.querySelector('#modalContent').innerHTML=html; modal.classList.add('active'); }
function closeModal(){ modal.classList.remove('active'); }

async function requireAdmin(){
  state.sb=await getSupabaseClient();
  const {data:{session}}=await state.sb.auth.getSession();
  if(!session){ location.replace('admin-login.html'); return false; }
  const {data:allowed,error}=await state.sb.rpc('is_admin');
  if(error || !allowed){ await state.sb.auth.signOut(); location.replace('admin-login.html'); return false; }
  document.querySelector('#adminEmail').textContent=session.user.email;
  document.querySelector('#settingsEmail').textContent=session.user.email;
  return true;
}

async function loadAll(){
  const [orders,customers,products,collections]=await Promise.all([
    state.sb.from('orders').select('*,order_items(*)').order('created_at',{ascending:false}),
    state.sb.from('customers').select('*').order('created_at',{ascending:false}),
    state.sb.from('products').select('*,collections(id,name),product_images(*)').order('created_at',{ascending:false}),
    state.sb.from('collections').select('*').order('sort_order')
  ]);
  for(const result of [orders,customers,products,collections]) if(result.error) throw result.error;
  state.orders=orders.data||[];state.customers=customers.data||[];state.products=products.data||[];state.collections=collections.data||[];
  renderAll();
}

function renderAll(){ renderOverview();renderOrders();renderCustomers();renderProducts();renderCollections();renderSales(); }
function renderOverview(){
  const counts=s=>state.orders.filter(o=>o.status===s).length;
  const totalSales=state.orders.filter(o=>o.status==='completed').reduce((n,o)=>n+Number(o.total_amount),0);
  const metrics=[['Total Orders',state.orders.length],['Pending',counts('pending')],['Confirmed',counts('confirmed')],['Processing',counts('processing')],['Completed',counts('completed')],['Cancelled',counts('cancelled')],['Customers',state.customers.length],['Products',state.products.length],['Total Sales',money(totalSales)]];
  document.querySelector('#metrics').innerHTML=metrics.map(([l,v])=>`<div class="card"><span class="muted">${l}</span><div class="metric">${v}</div></div>`).join('');
  document.querySelector('#recentOrders').innerHTML=orderTable(state.orders.slice(0,8));
}
function orderTable(items){ return table(['Order','Customer','Phone','Date','Total','Status',''],items.map(o=>`<tr><td>${esc(o.order_number)}</td><td>${esc(o.customer_name_snapshot)}</td><td>${esc(o.phone_snapshot)}</td><td>${date(o.created_at)}</td><td>${money(o.total_amount)}</td><td><span class="status">${esc(o.status)}</span></td><td><button class="btn secondary" data-action="view-order" data-id="${o.id}">View</button></td></tr>`).join('')); }
function renderOrders(){
  const q=document.querySelector('#orderSearch').value.toLowerCase(),status=document.querySelector('#orderStatus').value;
  const rows=state.orders.filter(o=>(!status||o.status===status)&&(!q||`${o.order_number} ${o.customer_name_snapshot} ${o.phone_snapshot}`.toLowerCase().includes(q)));
  document.querySelector('#ordersTable').innerHTML=orderTable(rows);
}
function renderCustomers(){
  const q=document.querySelector('#customerSearch').value.toLowerCase();
  const rows=state.customers.filter(c=>!q||`${c.full_name||c.name||''} ${c.phone||''}`.toLowerCase().includes(q)).map(c=>{const orders=state.orders.filter(o=>o.customer_id===c.id),spent=orders.filter(o=>o.status==='completed').reduce((n,o)=>n+Number(o.total_amount),0);return `<tr><td>${esc(c.full_name||c.name)}</td><td>${esc(c.phone)}</td><td>${esc(c.governorate)}</td><td>${orders.length}</td><td>${money(spent)}</td><td><button class="btn secondary" data-action="view-customer" data-id="${c.id}">View</button></td></tr>`}).join('');
  document.querySelector('#customersTable').innerHTML=table(['Name','Phone','Governorate','Orders','Completed Purchases',''],rows);
}
function renderProducts(){
  const rows=state.products.map(p=>`<tr><td><img class="product-thumb" src="${esc((p.product_images||[]).sort((a,b)=>a.sort_order-b.sort_order)[0]?.image_url||'')}" alt=""></td><td>${esc(p.name)}</td><td>${esc(p.collections?.name)}</td><td>${money(p.price)}</td><td>${p.is_active?'Active':'Inactive'}</td><td><button class="btn secondary" data-action="edit-product" data-id="${p.id}">Edit</button></td></tr>`).join('');
  document.querySelector('#productsTable').innerHTML=table(['Image','Name','Collection','Price','Status',''],rows);
}
function renderCollections(){
  const rows=state.collections.map(c=>`<tr><td>${esc(c.name)}</td><td>${esc(c.slug)}</td><td>${c.sort_order}</td><td>${c.is_active?'Active':'Inactive'}</td><td><button class="btn secondary" data-action="edit-collection" data-id="${c.id}">Edit</button></td></tr>`).join('');
  document.querySelector('#collectionsTable').innerHTML=table(['Name','Slug','Order','Status',''],rows);
}
function renderSales(){
  const completed=state.orders.filter(o=>o.status==='completed'),total=completed.reduce((n,o)=>n+Number(o.total_amount),0),sold={};
  completed.flatMap(o=>o.order_items||[]).forEach(i=>{const key=i.product_name_snapshot;sold[key]=(sold[key]||0)+Number(i.quantity)});
  document.querySelector('#salesMetrics').innerHTML=`<div class="card"><span class="muted">Completed Sales</span><div class="metric">${money(total)}</div></div><div class="card"><span class="muted">Completed Orders</span><div class="metric">${completed.length}</div></div>`;
  document.querySelector('#salesProducts').innerHTML=`<h2>Best-selling Products</h2>${table(['Product','Units'],Object.entries(sold).sort((a,b)=>b[1]-a[1]).map(([n,q])=>`<tr><td>${esc(n)}</td><td>${q}</td></tr>`).join(''))}`;
}

function showOrder(id){const o=state.orders.find(x=>x.id===id);if(!o)return;openModal(`<h2>Order ${esc(o.order_number)}</h2><div class="grid"><div class="card"><h3>Customer</h3><p>${esc(o.customer_name_snapshot)}<br>${esc(o.phone_snapshot)}<br>${esc(o.governorate_snapshot)}<br>${esc(o.address_snapshot)}</p></div><div class="card"><h3>Order</h3><p>${date(o.created_at)}<br>Total: ${money(o.total_amount)}</p><select id="modalStatus">${['pending','confirmed','processing','shipped','completed','cancelled'].map(s=>`<option ${s===o.status?'selected':''}>${s}</option>`).join('')}</select><br><br><button class="btn" data-action="save-status" data-id="${o.id}">Save Status</button></div></div><h3>Products</h3>${table(['Image','Product','Size','Color','Qty','Unit','Subtotal'],(o.order_items||[]).map(i=>`<tr><td><img class="product-thumb" src="${esc(i.product_image_snapshot)}"></td><td>${esc(i.product_name_snapshot)}</td><td>${esc(i.selected_size)}</td><td>${esc(i.selected_color)}</td><td>${i.quantity}</td><td>${money(i.unit_price)}</td><td>${money(i.subtotal)}</td></tr>`).join(''))}`);}
function showCustomer(id){const c=state.customers.find(x=>x.id===id),orders=state.orders.filter(o=>o.customer_id===id);openModal(`<h2>${esc(c.full_name||c.name)}</h2><p>${esc(c.phone)}<br>${esc(c.governorate)}<br>${esc(c.address)}</p><h3>Order History</h3>${orderTable(orders)}`);}
function productForm(p={}){const images=(p.product_images||[]).sort((a,b)=>a.sort_order-b.sort_order);openModal(`<h2>${p.id?'Edit':'Add'} Product</h2><form id="productForm" data-id="${p.id||''}" class="form-grid"><input class="input" name="name" placeholder="Name" value="${esc(p.name)}" required><input class="input" name="slug" placeholder="Slug" value="${esc(p.slug)}" required><textarea class="input span-2" name="description" placeholder="Description">${esc(p.description)}</textarea><input class="input" name="price" type="number" min="0" step="0.01" value="${p.price??''}" required><select name="collection_id"><option value="">No collection</option>${state.collections.map(c=>`<option value="${c.id}" ${c.id===p.collection_id?'selected':''}>${esc(c.name)}</option>`).join('')}</select><input class="input" name="sizes" placeholder="Sizes: M, L, XL" value="${esc(csv(p.available_sizes))}"><input class="input" name="colors" placeholder="Colors: Black, White" value="${esc(csv(p.available_colors))}"><input class="input" name="stock_quantity" type="number" min="0" placeholder="Stock (blank = untracked)" value="${p.stock_quantity??''}"><label><input name="is_active" type="checkbox" ${p.is_active!==false?'checked':''}> Active</label><input class="input span-2" name="image_url" placeholder="Image URL or local filename" value="${esc(images[0]?.image_url)}"><input class="input span-2" name="image_file" type="file" accept="image/*"><button class="btn span-2">Save Product</button></form>`);}
function collectionForm(c={}){openModal(`<h2>${c.id?'Edit':'Add'} Collection</h2><form id="collectionForm" data-id="${c.id||''}" class="form-grid"><input class="input" name="name" placeholder="Name" value="${esc(c.name)}" required><input class="input" name="slug" placeholder="Slug" value="${esc(c.slug)}" required><textarea class="input span-2" name="description" placeholder="Description">${esc(c.description)}</textarea><input class="input" name="sort_order" type="number" value="${c.sort_order??0}"><label><input name="is_active" type="checkbox" ${c.is_active!==false?'checked':''}> Active</label><input class="input span-2" name="image_url" placeholder="Image URL or local filename" value="${esc(c.image_url)}"><input class="input span-2" name="image_file" type="file" accept="image/*"><button class="btn span-2">Save Collection</button></form>`);}
async function upload(file,prefix){if(!file)return '';const safe=file.name.replace(/[^a-zA-Z0-9._-]/g,'-'),path=`${prefix}/${Date.now()}-${safe}`;const {error}=await state.sb.storage.from('product-images').upload(path,file,{upsert:false});if(error)throw error;return state.sb.storage.from('product-images').getPublicUrl(path).data.publicUrl;}
async function saveProduct(form){const fd=new FormData(form),id=form.dataset.id;let image=fd.get('image_url').trim();const file=fd.get('image_file');if(file?.size)image=await upload(file,'products');const payload={name:fd.get('name').trim(),slug:fd.get('slug').trim(),description:fd.get('description').trim(),price:Number(fd.get('price')),collection_id:fd.get('collection_id')||null,available_sizes:fd.get('sizes').split(',').map(x=>x.trim()).filter(Boolean),available_colors:fd.get('colors').split(',').map(x=>x.trim()).filter(Boolean),stock_quantity:fd.get('stock_quantity')===''?null:Number(fd.get('stock_quantity')),is_active:fd.get('is_active')==='on'};const result=id?await state.sb.from('products').update(payload).eq('id',id).select().single():await state.sb.from('products').insert(payload).select().single();if(result.error)throw result.error;const productId=result.data.id;if(image){const existing=state.products.find(p=>p.id===productId)?.product_images?.sort((a,b)=>a.sort_order-b.sort_order)[0];const imgPayload={product_id:productId,image_url:image,sort_order:0,alt_text:payload.name};const imgResult=existing?await state.sb.from('product_images').update(imgPayload).eq('id',existing.id):await state.sb.from('product_images').insert(imgPayload);if(imgResult.error)throw imgResult.error;}closeModal();await loadAll();notice('Product saved.');}
async function saveCollection(form){const fd=new FormData(form),id=form.dataset.id;let image=fd.get('image_url').trim(),file=fd.get('image_file');if(file?.size)image=await upload(file,'collections');const payload={name:fd.get('name').trim(),slug:fd.get('slug').trim(),description:fd.get('description').trim(),image_url:image||null,sort_order:Number(fd.get('sort_order')||0),is_active:fd.get('is_active')==='on'};const result=id?await state.sb.from('collections').update(payload).eq('id',id):await state.sb.from('collections').insert(payload);if(result.error)throw result.error;closeModal();await loadAll();notice('Collection saved.');}

document.addEventListener('click',async e=>{const button=e.target.closest('[data-action]');if(!button)return;try{const {action,id}=button.dataset;if(action==='close-modal')closeModal();if(action==='view-order')showOrder(id);if(action==='view-customer')showCustomer(id);if(action==='edit-product')productForm(state.products.find(x=>x.id===id));if(action==='new-product')productForm();if(action==='edit-collection')collectionForm(state.collections.find(x=>x.id===id));if(action==='new-collection')collectionForm();if(action==='save-status'){const {error}=await state.sb.from('orders').update({status:document.querySelector('#modalStatus').value}).eq('id',id);if(error)throw error;closeModal();await loadAll();notice('Order status updated.');}}catch(err){notice(err.message,true);}});
document.addEventListener('submit',async e=>{try{if(e.target.id==='productForm'){e.preventDefault();await saveProduct(e.target)}if(e.target.id==='collectionForm'){e.preventDefault();await saveCollection(e.target)}}catch(err){notice(err.message,true)}});
document.querySelector('#adminNav').addEventListener('click',e=>{const b=e.target.closest('[data-section]');if(!b)return;document.querySelectorAll('.nav-btn,.section').forEach(x=>x.classList.remove('active'));b.classList.add('active');document.querySelector(`#${b.dataset.section}`).classList.add('active');document.querySelector('#pageTitle').textContent=b.textContent;});
document.querySelector('#orderSearch').addEventListener('input',renderOrders);document.querySelector('#orderStatus').addEventListener('change',renderOrders);document.querySelector('#customerSearch').addEventListener('input',renderCustomers);document.querySelector('#refreshButton').addEventListener('click',()=>loadAll().catch(e=>notice(e.message,true)));document.querySelector('#logoutButton').addEventListener('click',async()=>{await state.sb.auth.signOut();location.replace('admin-login.html')});modal.addEventListener('click',e=>{if(e.target===modal)closeModal()});

if(await requireAdmin()) loadAll().catch(e=>notice(e.message,true));
