import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocCnvComponent } from './doc-cnv.component';

describe('DocCnvComponent', () => {
  let component: DocCnvComponent;
  let fixture: ComponentFixture<DocCnvComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocCnvComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocCnvComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
