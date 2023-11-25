import fetch from 'node-fetch';
import querystring from 'querystring';

const bucket = 'rblogxxx'; // 指定存储空间名称
const prefix = ''; // 指定前缀，只有资源名匹配该前缀的资源会被列出

// 构建请求参数对象
const params = {
  bucket,
  prefix,
};

// 构建请求URL
const url = `https://rsf.qiniuapi.com/photos/list?${querystring.stringify(params)}`;

// 设置请求头信息
const headers = {
  'Content-Type': 'application/x-www-form-urlencoded',
  'X-Qiniu-Date': new Date().toISOString(),
  Authorization: 'Qiniu MrE1BwSIpTfjX0S5mfw2Lw5rRfqi-k_ts6YhAWaA',
};

fetch(url, { headers })
  .then(response => console.log(response))
  .then(data => {
    // 处理返回的数据
    console.log(data);
  })
  .catch(error => {
    console.error('Error:', error);
  });