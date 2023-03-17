"""
    sphinxcontrib.pdfconverter
    ~~~~~~~~~~~~~~~~~~~~~~~

    Image converter extension for Sphinx

    :copyright: Copyright 2007-2022 by the Sphinx team, see AUTHORS.
    :license: BSD, see LICENSE for details.
"""

import subprocess
import sys
from os.path import splitext
from subprocess import PIPE, CalledProcessError
from typing import Any, Dict

from sphinx.application import Sphinx
from sphinx.errors import ExtensionError
from sphinx.locale import __
from sphinx.transforms.post_transforms.images import ImageConverter
from sphinx.util import logging

logger = logging.getLogger(__name__)


class PopplerConverter(ImageConverter):
    conversion_rules = [
        ('application/pdf', 'image/png'),
    ]

    def is_available(self) -> bool:
        """Confirms the converter is available or not."""
        try:
            args = [self.config.pdf_converter, '-v']
            logger.debug('Invoking %r ...', args)
            subprocess.run(args, stdout=PIPE, stderr=PIPE, check=True)
            return True
        except OSError as exc:
            logger.warning(__('convert command %r cannot be run, '
                              'check the pdf_converter setting: %s'),
                           self.config.pdf_converter, exc)
            return False
        except CalledProcessError as exc:
            logger.warning(__('convert exited with error:\n'
                              '[stderr]\n%r\n[stdout]\n%r'),
                           exc.stderr, exc.stdout)
            return False

    def convert(self, _from: str, _to: str) -> bool:
        """Converts the image to expected one."""
        to = splitext(_to)[0]
        try:
            args = ([self.config.pdf_converter] +
                    self.config.pdf_converter_args +
                    [_from, to])
            logger.debug('Invoking %r ...', args)
            subprocess.run(args, stdout=PIPE, stderr=PIPE, check=True)
            return True
        except OSError:
            logger.warning(__('convert command %r cannot be run, '
                              'check the pdf_converter setting'),
                           self.config.pdf_converter)
            return False
        except CalledProcessError as exc:
            raise ExtensionError(__('convert exited with error:\n'
                                    '[stderr]\n%r\n[stdout]\n%r') %
                                 (exc.stderr, exc.stdout)) from exc


def setup(app: Sphinx) -> Dict[str, Any]:
    app.add_post_transform(PopplerConverter)
    # Only really works with pdftoppm.  Kept this from imgconverter in case
    # other converters show up that work.
    app.add_config_value('pdf_converter', 'pdftoppm', 'env')
    app.add_config_value('pdf_converter_args', ['-png', '-singlefile'], 'env')

    return {
        'version': 'builtin',
        'parallel_read_safe': True,
        'parallel_write_safe': True,
    }
