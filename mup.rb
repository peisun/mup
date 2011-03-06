#!/opt/local/bin/ruby
# -*- coding: utf-8 -*-
# last updated : 
# Goal: money.orgを計算する
# ** <yyyy-mm-dd> 物品 金額 支払い　:費目:
#
require 'date'

Payout = { "食費"=>0,
  "タバコ"=>1,
  "交通費"=>2,
  "飲料物"=>3,
  "外食"=>4,
  "光熱費"=>5,
  "書籍・文具"=>6,
  "書籍文具"=>6,
  "書籍"=>6,
  "本"=>6,
  "文具"=>6,
  "おやつ"=>4,
  "おかし"=>4,
  "交際費"=>4,
  "医療費"=>7,
  "居住費"=>8,
  "住居費"=>8,
  "PC"=>9,
  "電子部品"=>9,
  "娯楽費"=>10,
  "TSUTAYA"=>10,
  "その他"=>11}
Outway = { "現金"=>0,
  "suica"=>1,
  "Suica"=>1,
  "Card"=>2,
  "card"=>2,
  "振込"=>0,
  "振込み"=>0}
St_buy = Struct.new("Payment",:date,:goods,:pay,:payout,:category)
class Category
  def initialize
    @category_total = Array.new
    Payout.each do |key, value|
      if(@category_total[value] == nil)
        @category_total[value] = Array.new([key,0])
      end
    end
  end
  def add(buy)
    if(Payout[buy.category] != nil) then
      @category_total[Payout[buy.category]][1]+=buy.pay
    else
      print("#{buy.date.strftime("%Y-%m-%d")}の記録で、")
      print("カテゴリ:#{buy.category}がありません。\n")
      print("mup.rbにカテゴリを追加してください。\n")
      exit 1
    end
  end
  def print(f)
    f.print("** Category\n")
    @category_total.each do |x|
      f.print("*** #{x[0]} #{x[1]}\n")
    end
  end
end
class Day
  def initialize(day)
    @date = day
    @total = 0
    @day = Array.new
  end
  def add(buy)
    @total += buy.pay
    str = "#{buy.date.strftime("%Y-%m-%d %a")} #{buy.goods} #{buy.pay} #{buy.payout}"
    @day << str
#    puts "Day pay = #{buy.pay} total = #{@total}"
  end
  def total
    return @total
  end
  def print(f)
    date_str = @date.strftime("%Y-%m-%d %a")
    f.print("*** #{date_str} #{@total}\n")
    f.print("    file:#{$realpath}::#{date_str}\n")
    @day.each do |x|
      f.print("**** #{x}\n")
    end
  end
  def print_this_month
    
  end
end
class Payway
  def initialize
    @way_total = Array.new
    Outway.each do |key, value|
      if(@way_total[value] == nil)
        @way_total[value] = Array.new([key,0])
      end
    end
  end
  def add(buy)
    if(@way_total[Outway[buy.payout]] != nil)
       @way_total[Outway[buy.payout]][1] +=buy.pay
     else
      print("#{buy.date.strftime("%Y-%m-%d")}の記録で、")
      print("支払い方法:#{category}がありません。\n")
      print("nmup.rbに支払い方法を追加してください。\n")
      exit 1
     end
  end
  def print(f)
    f.print("** Way\n")
    @way_total.each do |x|
      f.print("*** #{x[0]} #{x[1]}\n")
    end
  end
end
class Month
  def initialize
    @date = nil
    @daily = Array.new(32,nil)
    @category = Category.new
    @payway = Payway.new
  end
  def this_month_str
    return @date.strftime("%Y_%m")
  end
  def add(buy)
    @date = buy.date
    if(@daily[buy.date.day] == nil) then
      @daily[buy.date.day] = Day.new(buy.date)
    end
    @daily[buy.date.day].add(buy)
    @category.add(buy)
    @payway.add(buy)
  end
  def total
    total = 0
    @daily.each do |day|
      if(day != nil) then
        total += day.total
      else
        next
      end
    end
    return total
  end
  def print(f)
    total = self.total
    date_str = @date.strftime("%Y-%m")
    f.print("* Money\n")
    f.print("** Total #{date_str} #{total}\n")

    @category.print(f)


    @payway.print(f)
    f.print("** Daily\n")
    @daily.each do |day|
      if(day == nil) then next end
      day.print(f)
    end
  end
  def category_strfmt
  end
end
def line_parse(line,no)
  item = line.split

  length = item.size
  if(length < 7) then
    print("記録が正しくない可能性があります。\n")
    print("#{no}行目の記録項目が少ないです。\n")
    exit 1
  end
  date_str = item[1].sub!("<","")

  category = item[length-1]
  category.gsub!(/:/,"")
  if(category == nil) 
    print("#{date_str}の記録で、カテゴリが入力されてません.")
    exit -1
  end
  
  payout = item[length-2]
  if(payout == nil) 
    print("#{date_str}の記録で、支払い方法が入力されてません.")
    exit -1
  end
 
  price = item[length-3]
  if(price == nil) 
    print("#{date_str}の記録で、金額が入力されてません.")
    exit -1
  end

  length -= 6 
  if(length > 1) then
    goods = item[3,length].join(" ")
  else
    goods = item[3]
  end
  if(goods == nil) 
    print("#{date_str}の記録で、品名が入力されてません.")
    exit -1
  end

  buy = St_buy.new(Date::parse(date_str),goods,price.to_i,payout,category)
  
  return buy
end
#
# main
#
name = ARGV.shift
$file = File.open(name)
$backup = File.open("./backup/"+name,"w")
$realpath = File::realpath($file)
$data = Array.new
$m = 0
n = 0
while line = $file.gets
  n+=1
  $backup.print(line)
  unless(line =~ /^\*\*/) then next end
  buy = line_parse(line,n)
  if($m != buy.date.month) then
    $month = Month.new
    $data << $month
    $m = buy.date.month
  end
  $month.add(buy)
end
$file.close
$backup.close

$data.each do |m|
  fname = m.this_month_str
  fname += "_money.org"
  begin
    wf = open(fname,"w")
  rescue
    puts "#{fname}ファイルが作れません。"
  else
    m.print(wf)
    puts "create #{fname}"
  end
end
