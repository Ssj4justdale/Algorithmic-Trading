#define DISCORD_BOTNAME "Algorithmic Bot"
#define DATE_TIME time2text(world.timeofday, "MM/DD/YYYY - hh:mm")
#define DATE_HOUR time2text(world.timeofday, "hh")
#define DATE_MINUTE time2text(world.timeofday, "mm")
#define CLOSED 0
#define OPEN 1
#define percent_change(v1,v2) round((((v2-v1) / abs(v1)) *100),0.01)

#define _DEFAULT_WEBHOOK "https://discordapp.com/api/webhooks/590121883870167040/dMr8YNXomRhoChApK9FScCilyEftFlRU_ivHuNomXSsqNn0dCisrE1gR6qaa-QyYpLdw"
#define _EARNINGSPLAY_WEBHOOK "https://discordapp.com/api/webhooks/590121132686835725/PCO1mXx8WLk-PNcwtejOECJ0PWbyD8yCl37vdtqnTZ2t_poupqy6_pDYoCfETmopl8Yg"
#define _POTENTIALBREAKOUTS_WEBHOOK "https://discordapp.com/api/webhooks/590133486761803776/dyF4sc1CpjAZ3lHK_7519pRrYAlsp7E06QMIOmwrnsRZY79GXHXHMzKZMz2s_cOqqyqk"
#define _DISCORDBOTUPDATES_WEBHOOK "https://discordapp.com/api/webhooks/591339675625586739/Mwp57LNyvk-InTZ6yjPyOzBDRcBvKwiVR1vLdEV2BCLeJIAB1Sls8sa9jQCWPdnaSd2Z"
#define VERSION "v2r4-beta"



#define BOT_EARNINGS "EARNINGS PLAY"
#define BOT_BREAKOUT "POTENTIAL BREAKOUTS"
world/
	loop_checks = 0



#define ALGO_EARNINGS "earningsdate_thisweek,sh_curvol_u500,sh_insiderown_o10,sh_price_u3,ta_rsi_os40"
#define ALGO_BREAKOUT "cap_small,fa_salesqoq_o30,sh_insttrans_o50,ta_rsi_30to45&ft=4"


#define SIMULATE_SAME_DAY FALSE
