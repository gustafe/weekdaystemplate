HOME=/home/gustaf
BIN=$(HOME)/prj/CalendarTemplate
CGI=$(HOME)/cgi-bin
deploy: veckodagar.cgi templates/veckodagar.tt
        cp $(BIN)/veckodagar.cgi $(CGI)/veckodagar.cgi
        cp $(BIN)/templates/veckodagar.tt $(CGI)/templates/veckodagar.tt
