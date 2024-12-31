#!/bin/bash

# 检查参数
if [ $# -ne 1 ]; then
    echo "使用方法: $0 <domain>"
    echo "例如: $0 ecmarkets.work"
    exit 1
fi

# 获取域名参数
DOMAIN=$1

# 定义配置文件数组
conf_files=(ec-website.conf ec-api.conf ec-file-s3.conf ec-mobile.conf ec-client.conf ec-ib.conf ec-popularize-link.conf ec-landing-page.conf)

# 定义域名前缀数组
prefixes=(
"www.$DOMAIN $DOMAIN"
"api.$DOMAIN"
"file.$DOMAIN"
"m.$DOMAIN"
"crm.$DOMAIN"
"ib.$DOMAIN"
"i.$DOMAIN"
"r.$DOMAIN"
)

# Nginx配置文件目录
NGINX_CONF_DIR="/etc/nginx/conf.d"
#NGINX_CONF_DIR="/home/ecmarkets/conf.d.bak"

# 遍历数组，追加到配置文件
for i in "${!conf_files[@]}"; do
    config_file="${NGINX_CONF_DIR}/${conf_files[$i]}"
    domain_str="${prefixes[$i]}"

    # 读取当前配置文件中的 server_name 行，并确保用空格分隔
    current_server_names=$(grep "server_name" "$config_file" | sed 's/.*server_name[[:space:]]\+\(.*\);/\1/')

        # 调试输出
    echo "检查文件: ${conf_files[$i]}"
    echo "当前要添加的域名: $domain_str"
    echo "当前配置中的域名: $current_server_names"

    # 将域名字符串转换为数组
    IFS=' ' read -r -a check_domains <<< "$domain_str"

    # 需要添加的新域名
    new_domains=""

    # 检查每个域名
    for domain in "${check_domains[@]}"; do
        # 确保domain不为空
        if [ -n "$domain" ]; then
            # 调试输出
            echo "正在检查域名: $domain"
            if ! grep -wq "$domain" <<< "$current_server_names"; then
                echo "发现新域名: $domain"
                new_domains="$new_domains $domain"
            else
                echo "域名已存在: $domain"
            fi
        fi
    done

    # 如果有新域名需要添加
    if [ ! -z "$new_domains" ]; then
        if grep -q "server_name" "$config_file"; then
           sudo sed -i "/server_name/ s/;/$new_domains;/" "$config_file"
        else
            echo "    server_name$new_domains;" >> "$config_file"
        fi
        echo "更新 ${conf_files[$i]} 完成，添加了:$new_domains"
    else
        echo "${conf_files[$i]} 已包含所有域名，无需更新"
    fi
done


sudo nginx -t && sudo nginx -s reload
