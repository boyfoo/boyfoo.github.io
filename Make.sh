docker run --mount type=bind,source=$(pwd),target=/srv/jekyll \
-p 4000:4000 --name blog --rm -it jekyll/jekyll \
jekyll serve
