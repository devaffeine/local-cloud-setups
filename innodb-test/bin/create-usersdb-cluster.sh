kubectl create secret generic usersdb-pwds \
        --from-literal=rootUser=root \
        --from-literal=rootHost=% \
        --from-literal=rootPassword="asd123"

kubectl apply -f cfg/usersdb.mysql.yml
