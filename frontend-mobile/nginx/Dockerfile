FROM nginx:1.27-alpine

# Xóa config mặc định của nginx
RUN rm /etc/nginx/conf.d/default.conf

# Copy config của chúng ta
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# Nginx tự khởi động với "daemon off;" (chạy foreground — cần cho Docker)
CMD ["nginx", "-g", "daemon off;"]
