proc/PERCENT() . = (args.len > 1 ? (args[1] * (args[2]/100)) : args[1]/100)


algorithm
	var
		list
			age[] = list()
			securities[] = list()
			possibilities[] = list()

		cash = 5000

		_sharesMin = 15
		_sharesMax = 50

		_rebalance_waitTime = 10

		_maxHoldDays = 3

		_type

		_name

		tmp

			market = CLOSED

			hh;mm

			open_value
			portfolio_value

			cycle_began = 0

			DISCORD = _DEFAULT_WEBHOOK
			base_url = "https://finviz.com/screener.ashx?f="

			_rebalanceEveryHour = FALSE

			_ticker = 0

			_afterHours = FALSE

	proc
		_order(_orderType, _equity, _costPerShare, _shareQTY,_dontForce=1)
			if(market == CLOSED && !_afterHours)return
			switch(ckey(_orderType))
				if("limitbuy")
					world.log << "Attemtping to buy [_equity] at [_costPerShare]/share for [_shareQTY] shares"
					while(cash < (_shareQTY * _costPerShare))
						_shareQTY--
					if(_shareQTY <=0)
						world.log <<"Not enough money to buy [_equity]"
						return
					if(_costPerShare <= 0 || !_costPerShare)
						world.log <<"Failed to retrieve share price for [_equity]"
						return
					if(_equity in securities)
						if(_dontForce)
							if(securities[_equity]["average"] <= _costPerShare)
								world.log<<"[_equity] is too expensive at [_costPerShare]/share, average is [securities[_equity]["average"]]/share"
								return
						_averageDown(securities[_equity]["shares"],securities[_equity]["average"],_shareQTY,_costPerShare,_equity)
					else
						securities[_equity]=list()
						securities[_equity]["shares"] = _shareQTY
						securities[_equity]["average"] = _costPerShare
					age[_equity] = 0

					cash -= _shareQTY * _costPerShare
					_log("Purchased [_shareQTY] shares of $[_equity] @ $[_costPerShare]/share")

				if("limitsell")
					world.log << "Attemping to sell [_equity] at [_costPerShare]/share"
					if(!_equity in securities)
						world.log << "Failed to sell [_equity] as we do not own any shares"
						return
					world.log <<"[DATE_TIME]: Attempting to sell [_equity] with age of [age[_equity]]"
					if(_equity in age)
						if(age[_equity] == 0)return
					_shareQTY = min(securities[_equity]["shares"],_shareQTY)
					securities[_equity] = null
					age[_equity] = 0
					securities -= _equity
					age -= _equity
					cash += _costPerShare * _shareQTY
					_log("Sold [_shareQTY] shares of $[_equity] @ $[_costPerShare]/share")
				if("marketbuy")
					_costPerShare=_getStockValue(_equity)
					while(cash < (_shareQTY * _costPerShare))
						_shareQTY--
					if(_shareQTY <=0)return
					if(_equity in securities)
						if(_dontForce)
							if(securities[_equity]["average"] < _costPerShare)return
						_averageDown(securities[_equity]["shares"],securities[_equity]["average"],_shareQTY,_costPerShare,_equity)
					else
						securities[_equity]=list()
						securities[_equity]["shares"] = _shareQTY
						securities[_equity]["average"] = _costPerShare
					age[_equity]=0
					cash -= _shareQTY * _costPerShare
					_log("Purchased [_shareQTY] shares of $[_equity] @ $[_costPerShare]/share")
				if("marketsell") return
			_save()

		_fireSale(_equity)
			var/tmpvar1 = _getStockValue(_equity)
			var/tmpvar2 = securities[_equity]["shares"]
			_order("limitsell", _equity, tmpvar1, tmpvar2)

		_newDay()
			open_value = _portfolioValue()
			shell("rm -f data/*")
			for(var/_equity in securities)
				if(age[_equity] >= _maxHoldDays) _fireSale(_equity)
				else if(!SIMULATE_SAME_DAY) {age[_equity] += 1}
			_rebalance()

		_rebalance()
			for(var/_equity in securities)
				if(_equity in age)if(age[_equity] == 0)continue
				var/tmpvar1 = securities[_equity]["average"]
				var/tmpvar2 = _getStockValue(_equity)
				if(tmpvar2 > tmpvar1) _fireSale(_equity)
			_myPlay()
			_updateProgress()

		_getShares()
			. = args[1]
			if(. in securities)

				. = securities[.]["shares"]
			else . = 0

		_getAverage()
			. = args[1]
			if(. in securities)
				. = securities[.]["average"]
			else . = 0

		_averageDown(_primaryShares, _primaryAVG, _purchaseShares, _purchaseAVG,_equity)
			securities[_equity]["average"] = ((_primaryShares * _primaryAVG) + (_purchaseShares * _purchaseAVG)) / (_primaryShares + _purchaseShares)
			securities[_equity]["shares"] = (_primaryShares + _purchaseShares)
			world.log<<"Averaging Down on [_equity]"

		_portfolioValue()
			. = 0
			for(var/_eq in securities)
				. += (_getShares(_eq) * _getStockValue(_eq))
			. += cash

		_updatePortfolioDiscord()


		_log(_x, DISCORD_S = DISCORD)
			world.log << args[1];shell("curl -H \"Content-Type: application/json\" -X POST -d '{\"username\": \"[_name]\", \"content\": \"[args[1]]\"}' [DISCORD_S]")
		_logBOT()
			world.log << args[1];shell("curl -H \"Content-Type: application/json\" -X POST -d '{\"username\": \"[_name]\", \"content\": \"[args[1]]\"}' [_DEFAULT_WEBHOOK]")

		_randomShares()
			. = rand(_sharesMin,_sharesMax)

		_save()
			var/savefile/_save = new("saves/[_type]")
			_save["age"] << src.age
			_save["securities"] << src.securities
			_save["cash"] << src.cash
			_save["open"] << src.open_value

		_load()
			_type = args[1]
			switch(_type)
				if(BOT_EARNINGS){.=_EARNINGSPLAY_WEBHOOK; _name = "ALGORITHMIC EARNINGS BOT";}
				if(BOT_BREAKOUT){.=_POTENTIALBREAKOUTS_WEBHOOK; _name = "ALGORITHMIC BREAKOUTS BOT";}
			DISCORD = .
			if(fexists("saves/[_type]"))
				var/savefile/_save = new("saves/[_type]")
				_save["age"] >> src.age
				_save["securities"] >> src.securities
				_save["cash"] >> src.cash
				_save["open"] >> src.open_value
			_beginCycle()

		_createData(_dataSource)
			. = "[rand(000000,999999)]"
			if(fexists("data/[.]"))fdel("data/[.]")
			shell("curl \"[_dataSource]\" -o \"data/[.]\"")

		_dataFile(_string, _file=0)
			. = _file ? file("data/[_string]") : "data/[_string]"

		_dataFile2Text(_string)
			. = istext(_string) ? file2text("data/[_string]") : _string

		_runAlgorithm()
			.=null
			. = _createData(base_url+args[1])
			.=_getInstances(_dataFile2Text(.),{"<td height="10" align="right" class="screener-body-table-nw"><a href="quote.ashx?t="},"&","</tr>")

		_updateProgress()
			portfolio_value = _portfolioValue(); . = percent_change(open_value, portfolio_value)
			_log("$[portfolio_value] ([. > 0 ? "+" : ""][.]%)", _DISCORDBOTUPDATES_WEBHOOK)
			var/cur_val			
			for(var/_equity in securities)
				cur_val = _getStockValue(_equity)
				. = percent_change(securities[_equity]["average"], cur_val)
				_log("*Holding [securities[_equity]["shares"]] shares of $[_equity] @ an average of [securities[_equity]["average"]]/share -- Current Value: [cur_val]([. > 0 ? "+" : ""][.]%)*",_DISCORDBOTUPDATES_WEBHOOK)



		_getInstances(haystack, needle, delimiter, delimiter2)
			.=list()
			while(findtext(haystack,needle))
				haystack = copytext(haystack,findtext(haystack,needle)+length(needle))
				. += copytext(haystack,1,findtext(haystack,delimiter))
				if(delimiter2) haystack = copytext(haystack, findtext(haystack,delimiter2))

		_getStockValue(_equity)
			world.log << "Getting [_equity] Value"
			. = _createData("https://finance.yahoo.com/quote/[_equity]")
			. = _getInstances(_dataFile2Text(.), {""regularMarketPrice":{"raw":"}, ",\"fmt")
			. = text2num(list2params(.))
			world.log << "[_equity] is valued at [.]/share"

		_earningPlays()
			. = _runAlgorithm(ALGO_EARNINGS)

		_breakoutPlays()
			. = _runAlgorithm(ALGO_BREAKOUT)

		_myPlay()
			switch(_type)
				if(BOT_EARNINGS).=_earningPlays()
				if(BOT_BREAKOUT).=_breakoutPlays()
			var/tmpvar1
			for(var/_equity in .)
				tmpvar1 = _getStockValue(_equity)
				//tmpvar1 -= PERCENT(tmpvar1,1)
				//tmpvar1 = round(tmpvar1,0.01)
				_order("limitbuy",_equity,tmpvar1,_randomShares(),1)

		_beginCycle()
			spawn()
				if(cycle_began)return
				else cycle_began = 1
				while(src)
					_ticker++
					hh = text2num(DATE_HOUR)
					mm = text2num(DATE_MINUTE)
					switch(market)
						if(CLOSED)
							//hh = text2num(hh);mm = text2num(mm)
							if(SIMULATE_SAME_DAY){if(hh >= 6 && mm >= 30 && hh < 13 || hh >= 7 && hh < 13){market = OPEN;_newDay()}}
							else {if(hh >= 6 && mm >= 30 && hh < 13 || hh >= 7 && hh < 13){market = OPEN;_logBOT("[DATE_TIME] - Algorithmic [_type] Bot [VERSION] Signing On -- Portfolio Value: $[_portfolioValue()]");_newDay()}}
						if(OPEN)
							//hh = text2num(hh);mm=text2num(mm)
							if(hh >= 13 || hh >= 1 && hh < 6 || hh == 6 && mm < 30) {market = CLOSED; portfolio_value = _portfolioValue(); . = percent_change(open_value, portfolio_value); _logBOT("[DATE_TIME] - Algorithmic [_type] Bot [VERSION] Signing Off -- Portfolio Value: $[portfolio_value] ([. > 0 ? "+" : ""][.]%)");}

					sleep(600)
					if(_rebalanceEveryHour)
						if(mm == 0 || !mm || DATE_MINUTE == "00")
							_rebalance();_ticker=0
					else
						if((!_rebalanceEveryHour && _ticker >= _rebalance_waitTime) && market == OPEN)
							_ticker = 0;_rebalance()
					world.log << "[DATE_TIME] - Still Active"



var/algorithm/breakout_trader = new
var/algorithm/earnings_trader = new

world/New()
	spawn()breakout_trader._load(BOT_BREAKOUT)
	spawn()earnings_trader._load(BOT_EARNINGS)
	..()






