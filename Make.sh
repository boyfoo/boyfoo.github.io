docker stop zx-blog
docker run --name zx-blog --rm -d -v "$(pwd):/src" -p 4000:4000 grahamc/jekyll serve -H 0.0.0.0