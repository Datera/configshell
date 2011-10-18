# This file is part of ConfigShell Community Edition.
# Copyright (c) 2011 by RisingTide Systems LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, version 3 (AGPLv3).
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

NAME = configshell
GIT_BRANCH = $$(git branch | grep \* | tr -d \*)
VERSION = $$(basename $$(git describe --tags | tr - .))

all:
	@echo "Usage:"
	@echo
	@echo "  make deb         - Builds debian packages."
	@echo "  make rpm         - Builds rpm packages."
	@echo "  make release     - Generates the release tarball."
	@echo
	@echo "  make clean       - Cleanup the local repository build files."
	@echo "  make cleanall    - Also remove dist/*"

clean:
	@rm -fv ${NAME}/*.pyc ${NAME}/*.html
	@rm -frv doc
	@rm -frv ${NAME}.egg-info MANIFEST build
	@rm -frv debian/tmp
	@rm -fv build-stamp
	@rm -fv dpkg-buildpackage.log dpkg-buildpackage.version
	@rm -frv *.rpm
	@rm -fv debian/files debian/*.log debian/*.substvars
	@rm -frv debian/${NAME}-doc/ debian/python2.5-${NAME}/
	@rm -frv debian/python2.6-${NAME}/ debian/python-${NAME}/
	@rm -frv results
	@rm -fv rpm/*.spec *.spec rpm/sed* sed*
	@rm -frv ${NAME}-*
	@echo "Finished cleanup."

cleanall: clean
	@rm -frv dist

release: build/release-stamp
build/release-stamp:
	@mkdir -p build
	@echo "Exporting the repository files..."
	@git archive ${GIT_BRANCH} --prefix ${NAME}-${VERSION}/ \
		| (cd build; tar xfp -)
	@echo "Cleaning up the target tree..."
	@rm -f build/${NAME}-${VERSION}/Makefile
	@rm -f build/${NAME}-${VERSION}/.gitignore
	@echo "Fixing version string..."
	@sed -i "s/__version__ = .*/__version__ = '${VERSION}'/g" \
		build/${NAME}-${VERSION}/${NAME}/__init__.py
	@echo "Generating rpm specfile from template..."
	@cd build/${NAME}-${VERSION}; \
		for spectmpl in rpm/*.spec.tmpl; do \
			sed -i "s/Version:\( *\).*/Version:\1${VERSION}/g" $${spectmpl}; \
			mv $${spectmpl} $$(basename $${spectmpl} .tmpl); \
		done; \
		rm -r rpm
	@echo "Generating rpm changelog..."
	@for commit in $$(git log --date=iso  | grep -e ^commit -e ^Date: \
		| tr -d '\n' | sed 's/commit /\n/g' | sed 's/Date:  //g' \
		| awk '{print $$2, $$3, $$1}' | sort -r | awk '{print $$3}'); do \
		version=$$(basename $$(git describe $${commit} --tags | tr - .)); \
		author=$$(git show $${commit} --format="format:%an <%ae>" -s); \
		date=$$(git show $${commit} --format="format:%ad" -s \
			| awk '{print $$1,$$2,$$3,$$5}'); \
	   	echo '* '"$${date} $${author} $${version}-1"; \
		git show $${commit} --format="format:%s%n" -s; \
		git show $${commit} --format="format:%b" -s \
			| sed 's/^* /- /g' | sed 's/^/  /g'; \
	done >> $$(ls build/${NAME}-${VERSION}/*.spec)
	@echo "Generating debian changelog..."
	@for commit in $$(git log | grep ^commit | awk '{print $$2}'); do \
		version=$$(basename $$(git describe $${commit} --tags | tr - .)); \
		author=$$(git show $${commit} --format="format:%an <%ae>" -s); \
		date=$$(git show $${commit} --format="format:%aD" -s); \
		day=$$(git show $${commit} --format='format:%ai' -s \
			| awk -F '-' '{print $$2}'); \
		date=$$(echo $${date} \
			| awk '{print $$1, "'"$${day}"'", $$3, $$4, $$5, $$6}'); \
	   	echo "${NAME} ($${version}) unstable; urgency=low"; \
		echo ; \
		git show $${commit} --format="format:  * %s%n" -s; \
		git show $${commit} --format="format:%b%n" -s \
			| sed 's/^* /- /g' | sed 's/^/    /g'; \
		echo " -- $${author}  $${date}"; \
		echo ; \
	done > build/${NAME}-${VERSION}/debian/changelog
	@find build/${NAME}-${VERSION}/ -exec \
		touch -t $$(date -d @$$(git show -s --format="format:%at") \
			+"%Y%m%d%H%M.%S") {} \;
	@mkdir -p dist
	@cd build; tar -c --owner=0 --group=0 --numeric-owner \
		--format=gnu -b20 --quoting-style=escape \
		-f ../dist/${NAME}-${VERSION}.tar \
		$$(find ${NAME}-${VERSION} -type f | sort)
	@gzip -6 -n dist/${NAME}-${VERSION}.tar
	@echo "Generated release tarball:"
	@echo "    $$(ls dist/${NAME}-${VERSION}.tar.gz)"
	@touch build/release-stamp

deb: release build/deb-stamp
build/deb-stamp:
	@echo "Building debian packages..."
	@cd build/${NAME}-${VERSION}; \
		dpkg-buildpackage -rfakeroot -us -uc
	@mv build/*_${VERSION}_*.deb dist/
	@echo "Generated debian packages:"
	@for pkg in $$(ls dist/*_${VERSION}_*.deb); do echo "  $${pkg}"; done
	@touch build/deb-stamp

rpm: release build/rpm-stamp
build/rpm-stamp:
	@echo "Building rpm packages..."
	@mkdir -p build/rpm
	@build=$$(pwd)/build/rpm; dist=$$(pwd)/dist/; rpmbuild \
		--define "_topdir $${build}" --define "_sourcedir $${dist}" \
		--define "_rpmdir $${build}" --define "_buildir $${build}" \
		--define "_srcrpmdir $${build}" -ba build/${NAME}-${VERSION}/*.spec
	@mv build/rpm/*-${VERSION}*.src.rpm dist/
	@mv build/rpm/*/*-${VERSION}*.rpm dist/
	@echo "Generated rpm packages:"
	@for pkg in $$(ls dist/*-${VERSION}*.rpm); do echo "  $${pkg}"; done
	@touch build/rpm-stamp
