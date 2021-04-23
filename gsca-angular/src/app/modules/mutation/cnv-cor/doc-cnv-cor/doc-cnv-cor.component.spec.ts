import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocCnvCorComponent } from './doc-cnv-cor.component';

describe('DocCnvCorComponent', () => {
  let component: DocCnvCorComponent;
  let fixture: ComponentFixture<DocCnvCorComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocCnvCorComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocCnvCorComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
