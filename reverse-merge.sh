#!/bin/bash

# 变量
# 需要合并到的目标分支
mergeTo="master"
# 需要合并的来源分支
mergeFrom="pms"

git checkout ${mergeFrom}
#git pull


# 所有需要合并到上游分支的目录
. ./path-to-reverse-merge.sh
echo ${mergePath[*]}

# 获取到最后一次提交的commitId
commitId=`git log --pretty=format:"%h" | head -1  | awk '{print $1}'`

## Hard Reset 到上一次提交
#git reset --hard HEAD^
#
## 比较文件差异
#git diff ${commitId} --stat

# Hard Reset 到上一次提交
git reset --hard HEAD^
# 比较当前分支和远程分支的差异
changes=`git diff HEAD FETCH_HEAD --name-status`


echo "最新一次提交改动的文件为："
echo ${changes}


i=0
# A 新增   M 编辑   D 删除   R100 移动
for str in ${changes}
do
  if [ ${str} != "A" -a ${str} != "M" -a ${str} != "D" -a ${str} != "R100" ]; then

    for path in ${mergePath[*]}
    do
      regPath="^${path}.*"
      if [[ ${str} =~ ${regPath} ]]; then
        changeFiles[${i}]=${str}
        let i=i+1
      fi
    done

  fi
done

tempBranch="${mergeTo}-merge-${mergeFrom}-temp"

git checkout ${mergeTo}
git pull
git checkout -b ${tempBranch}


echo "最新一次提交改动的需要反向合到上游分支的文件为："
echo "总数：${i}"
for file in ${changeFiles[*]}
do
  git reset ${commitId} ${file}
done
# 撤销工作区的改动
git checkout -- .


git commit -m "chore merge ${mergeFrom} to ${mergeTo}"

git checkout ${mergeTo}
git pull
git merge ${tempBranch}
git branch -D ${tempBranch}
git push
