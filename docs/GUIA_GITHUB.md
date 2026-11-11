# Guía para publicar el repositorio en GitHub

1. En github.com: **New repository** -> nombre `lameseta-cxc` -> **Private** -> sin README (ya existe).
2. Settings -> Collaborators -> **Add people** -> escriba el correo que indicó el profesor.
3. En esta carpeta:
   ```
   git remote add origin https://github.com/SU_USUARIO/lameseta-cxc.git
   git branch -M main
   git push -u origin main
   ```
   (GitHub pedirá un Personal Access Token como contraseña, o use GitHub Desktop.)
4. Siga trabajando y haga `git add -A && git commit -m "mensaje" && git push` cada semana: el profesor
   revisa las contribuciones a lo largo del tiempo, así que no deje todo para el último día.
5. Pegue la URL del repositorio en el PDF (capítulo Código).
6. Antes de empezar a editar, corra los scripts en SQL Developer y corrija lo que falle; cada
   corrección en un commit aparte deja evidencia de su trabajo.
