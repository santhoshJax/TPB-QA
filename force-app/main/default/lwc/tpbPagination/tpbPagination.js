import { LightningElement, api } from 'lwc';

export default class TpbPagination extends LightningElement {
  _page = 1;
  @api get page() {
    return this._page;
  }
  set page(value) {
    this._page = parseInt(value, 10);
  }

  _pageSize = 25;
  @api get pageSize() {
    return this._pageSize;
  }
  set pageSize(value) {
    this._pageSize = parseInt(value, 10);
  }

  @api total = 0;

  windowSize = 10;

  get pageSizeOptions() {
    return [25, 50, 100].map((value) => {
      return { label: value, value: value };
    });
  }

  get maxPage() {
    return (
      Math.floor(this.total / this.pageSize) +
      (this.total % this.pageSize > 0 ? 1 : 0)
    );
  }

  get window() {
    const maxPage = this.maxPage;
    let page = this.page;
    let windowSize = this.windowSize; // default show 10 page numbers

    let start = page - Math.floor(windowSize / 2);
    if (start <= 0) {
      start = 1;
    }
    let end = start + windowSize - 1;
    if (end > maxPage) {
      end = maxPage;
    }
    const that = this;

    return Array.from(new Array(end - start + 1), (n, i) => start + i).map(
      (pageNum) => {
        return {
          label: pageNum,
          value: pageNum,
          get isCurrentPage() {
            return Number(that.page) === Number(pageNum);
          },
          onClick(/*e*/) {
            that.changePage(pageNum);
          }
        };
      }
    );
  }

  changePage(newPageNum) {
    this._page = parseInt(newPageNum, 10);
    const pageChangeEvent = new CustomEvent('pagechange', {
      detail: { page: this._page }
    });
    this.dispatchEvent(pageChangeEvent);
  }

  changePageSize(newPageSize) {
    this._pageSize = parseInt(newPageSize, 10);
    const pagesizeChangeEvent = new CustomEvent('pagesizechange', {
      detail: { pageSize: this._pageSize }
    });
    this.dispatchEvent(pagesizeChangeEvent);
  }

  get isFirstPage() {
    return this.page === 1;
  }

  get isLastPage() {
    return this.page === this.maxPage;
  }

  handleFirstPageClick() {
    this.changePage(1);
  }

  handlePrevPageClick() {
    const newPage = this.page - 1;
    const minPage = 1;
    this.changePage(newPage <= 0 ? minPage : newPage);
  }

  handleNextPageClick() {
    const newPage = this.page + 1;
    const maxPage = this.maxPage;
    this.changePage(newPage > maxPage ? maxPage : newPage);
  }

  handleLastPageClick() {
    this.changePage(this.maxPage);
  }

  handlePageSizeChange(e) {
    const { value } = e.detail;
    this.changePageSize(value);
  }
}