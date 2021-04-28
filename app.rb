require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

#(skiss, vilka tabeller, vilka funktioner?) Git upp + wiki

enable :sessions
db = SQLite3::Database.new('db/database.db')

get('/') do
  session_id = session[:id]

  if session_id != nil
    db.results_as_hash = true
    result = db.execute("SELECT * FROM products")
    p "Alla produkter"
    slim(:"products/index", locals: { products: result })
  else
    redirect('/login')
  end
end
get('/mypage') do
  session_id = session[:id]

  if session_id != nil
    db.results_as_hash = true
    result = db.execute("SELECT * FROM products")
    p "Alla produkter"
    slim(:"products/mypage", locals: { products: result, userid: session_id })
  else
    redirect('/login')
  end
end

# Login page
get('/login') do
  slim(:login)
end

# Login user
post('/login') do
  username = params[:username]
  password = params[:password]
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first
  begin
    pwdigest = result["pwdigest"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      redirect('/')
    else
      "FEL LÖSENORD!"
    end
  rescue 
    "FEL NAMN!"
  end
  
  
  
end

# Logout page
get('/logout') do
  session[:id] = nil
  session.destroy
  redirect('/')
end

# Login page
get('/register') do
  slim(:register)
end

# Get product ( la till session id variabeln för att endast kunna ta bort sina egna produkter)
get('/product/:id') do
  session_id = session[:id]
  
  if session_id == nil
    redirect('/login')
    return
  end

  id = params[:id]
  result =  db.execute("SELECT * FROM products WHERE id = ?", id)
  slim(:"products/product", locals: { product: result[0], userid: session_id })
end

# Delete product (ändrade till post, då delete inte fungerade atm.)
post('/product/:id/delete') do
  session_id = session[:id]
  
  if session_id == nil
    redirect('/login')
    return
  end

  id = params[:id]
  puts id
  db.execute("DELETE FROM products WHERE id = ?", id)
  redirect('/')
end

# Update product
put('/product/:id') do
  session_id = session[:id]
  
  if session_id == nil
    redirect('/login')
    return
  end

  id = params[:id]
  titel = params[:titel]
  besk = params[:beskrivning]
  pris = params[:pris]

  db.results_as_hash = true
  result = db.execute("UPDATE products SET content=? WHERE id=?", todo, id).first
  redirect('/')
end

# Create new product
post('/product/new') do
  session_id = session[:id]
  
  if session_id == nil
    redirect('/login')
    return
  end
  file = params[:image][:tempfile]
  filename = params[:image][:filename]
    
  if filename.include? ".jpg"
    ext = ".jpg"
  elsif filename.include? ".png"
    ext = ".png"
  elsif filename.include? ".gif"
    ext = ".gif"
  end

  
  titel = params[:titel]
  besk = params[:beskrivning]
  pris = params[:pris]
  db.results_as_hash = true
  db.execute("INSERT INTO products (titel, beskrivning, pris, userid, ext) VALUES (?,?,?,?,?)", titel, besk, pris, session_id, ext)
  if params[:image] && params[:image][:filename]
    

    path = "./public/img/#{db.last_insert_row_id.to_s + ext}"

    # Write file to disk
    File.open(path, 'wb') do |f|
      f.write(file.read)
    end
  end
  redirect('/')
end

# Create new user
post("/user") do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == password_confirm
    password_digest = BCrypt::Password.create(password)
    db.execute("INSERT INTO users (username, pwdigest) VALUES (?,?)", username, password_digest)
    redirect('/')
  else
    "Inkorrekt lösenord, försök igen!"
  end
end

