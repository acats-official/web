# Aristocats web v.3

![Aristocats!](img/misc/aristocats_logo.png)

Aristocats webbplats version 3 är skapad med målet att vara stabil, lättutvecklad, säker och så gott som kostnadsfri.
Sidan är statiskt generarad och GitHub står för både build, deploy och hosting. 
Hör av dig till någon av ägarna i repot för att bli `collaborator` och tillföra material.

## Lokal utvecklingsmiljö
1. Installera ruby och eventuellt ruby-dev.
2. Kör `bundle install` från rotkatalogen för att installera samtliga gems.
2. Kör `bundle exec jekyll serve` från rotkatalogen.
3. Jekylls utvecklingserver borde nu ha sidan tillgänglig på port 4000. 

## Skapa händelse i tidslinje
1. Kontakta någon av ägarna i repot för att få lämpliga behörigheter.
2. Klona ner repo:t.
3. Skapa en branch från `main` med ett rimligt namn.
4. Kopiera `/events/TEMPLATE.yml` och ge den ett passande namn.
5. Fyll i samtliga parametrar. Se övriga *.yml i /events för inspiration. 
5. Eventuella bilder läggs på rimlig plats i '/img/events/'. Komprimera ner bilder till jpg och under 1MB.
7. Kör jekyll lokalt och kontrollera att allt ser ut som tänkt.
8. Tänk på att inte lägga upp alltför personliga eller förnedrande texter och bilder...
9. Skicka upp din branch och skapa en PR.
10. Efter merge to main körs GitHub actions som bygger och deploy:ar sidan.

## Förbättringar
- Fördjupad och förlängd tidslinje.
- Lägg till swipe-support på tidslinjen.
- Generell förbättring av CSS/flytt av in-line styling.
- Aristocats-ifiera sidan ytterligare.
- En datumbaserad alternativ banner/dropdown/popup under nolle-p med exempelvis caps-regler.
